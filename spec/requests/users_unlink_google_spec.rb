require 'rails_helper'

# Unlinking is the recovery path when a Google sign-in is refused for "already
# linked to a different Google account" -- the pin is never re-bound
# automatically, so without this an affected user has no way back in via Google.
RSpec.describe 'Unlink Google (admin)', type: :request, google_sign_in: true do
  include_context 'users'

  let(:default_uid) { GoogleSignInHelper::DEFAULT_UID }
  let(:other_uid) { GoogleSignInHelper::OTHER_UID }

  def link!(user)
    user.update_columns(
      provider: GoogleSignIn::PROVIDER,
      uid: default_uid,
      google_email: user.email,
      google_linked_at: Time.current,
      google_given_name: 'Gina',
      google_family_name: 'Google'
    )
  end

  before { allow(GoogleSignIn).to receive(:enabled?).and_return(true) }

  it 'lets an administrator unlink, clearing every Google column' do
    link!(agent)
    sign_in(administrator)

    patch unlink_google_user_path(agent)

    expect(response).to redirect_to(edit_user_path(agent))
    agent.reload
    expect(agent).not_to be_google_linked
    expect(agent.attributes.values_at('provider', 'uid', 'google_email', 'google_linked_at',
                                      'google_given_name', 'google_family_name')).to all(be_nil)
  end

  # update!, not update_columns: who unlinked whom must be on the record.
  it 'records the unlink in the audit trail, attributed to the administrator' do
    link!(agent)
    sign_in(administrator)

    expect { patch unlink_google_user_path(agent) }.to change { agent.audits.count }.by(1)

    audit = agent.audits.last
    expect(audit.audited_changes['uid']).to eq([default_uid, nil])
    expect(audit.user).to eq(administrator)
  end

  it 'does not let a manager who can edit the user unlink them' do
    link!(agent)
    expect(UserPolicy.new(manager, agent).edit?).to be(true)
    sign_in(manager)

    patch unlink_google_user_path(agent)

    expect(response).to be_redirect
    expect(agent.reload.uid).to eq(default_uid)
  end

  it 'does not let an agent unlink anyone' do
    link!(agent2)
    sign_in(agent)

    patch unlink_google_user_path(agent2)

    expect(agent2.reload.uid).to eq(default_uid)
  end

  it 'never unlinks the system user' do
    system_user = User.system
    link!(system_user)
    sign_in(administrator)

    patch unlink_google_user_path(system_user)

    expect(system_user.reload.uid).to eq(default_uid)
  end

  it 'shows the Unlink control on the edit page to an administrator only' do
    link!(agent)

    sign_in(administrator)
    get edit_user_path(agent)
    assert_select 'a[href=?][data-method=patch]', unlink_google_user_path(agent)

    sign_out(administrator)
    sign_in(manager)
    get edit_user_path(agent)
    expect(response).to have_http_status(:ok)
    assert_select 'a[href=?]', unlink_google_user_path(agent), count: 0
  end

  it 're-links whichever Google account signs in next' do
    link!(agent)
    sign_in(administrator)
    patch unlink_google_user_path(agent)
    sign_out(administrator)

    sign_in_with_google(google_auth(email: agent.email, uid: other_uid))

    expect_signed_in_as(agent)
    expect(agent.reload.uid).to eq(other_uid)
  end
end
