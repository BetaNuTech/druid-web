require 'rails_helper'

# The privacy policy exists to satisfy Google's requirement for publishing the
# OAuth consent screen ("Sign in with Google"). Its critical property is being
# reachable WITHOUT signing in -- if it ever turns into a redirect to the sign-in
# form, nothing fails on our side; Google just rejects the consent screen.
RSpec.describe 'Privacy policy', type: :request do
  it 'is reachable without signing in' do
    get privacy_path

    expect(response).to have_http_status(:ok)
    expect(response.redirect_url.to_s).not_to match(/sign_in/)
  end

  it 'renders standalone, loading none of the scripts and assets it describes' do
    get privacy_path
    body = response.body

    expect(body).to match(/<!DOCTYPE html>/i)
    expect(body).to match(/<style>/)
    # No scripts and no external stylesheets of any kind: no analytics, no
    # monitoring agent, no web fonts, no application assets.
    expect(body).not_to match(/<script/i)
    expect(body).not_to match(/<link[^>]+stylesheet/i)
  end

  it 'is light-only, so a dark-themed browser does not render it black-on-black' do
    get privacy_path

    expect(response.body).to include('color-scheme: light')
    expect(response.body).to match(/body\s*\{[^}]*background-color:\s*#ffffff/m)
  end

  it 'names the current company, not the former names' do
    get privacy_path

    expect(response.body).to include('Bluecore Residential')
    expect(response.body).not_to match(/Bluecrest|BlueStone Properties/i)
  end

  # The specific representations Google's consent screen review cares about.
  # They must stay true to Users::OmniauthCallbacksController.
  it 'describes the Google data actually collected' do
    get privacy_path
    body = response.body

    expect(body).to match(/Sign in with Google/i)
    # True only while the callback controller keeps ignoring auth.credentials.
    expect(body).to match(/do not store Google access tokens or refresh tokens/i)
    # And only while no account is ever provisioned from Google.
    expect(body).to match(/never creates an account/i)
  end

  it 'carries the Google API Services User Data Policy Limited Use statement' do
    get privacy_path

    expect(response.body).to match(/Limited Use/)
    expect(response.body).to match(%r{developers\.google\.com/terms/api-services-user-data-policy})
  end

  # The cookie disclosure must match what the code actually sets. Cobalt's page
  # once claimed "a single session cookie" while Devise :rememberable was quietly
  # setting a persistent one. Tying these to the code means a change there fails
  # here, instead of the policy silently drifting out of date.
  describe 'cookie disclosure' do
    before { get privacy_path }

    it 'never claims a single cookie' do
      expect(response.body).not_to match(/single session cookie/i)
    end

    it 'discloses the remember-me cookie and its lifetime while :rememberable is on' do
      skip 'rememberable is off' unless User.devise_modules.include?(:rememberable)

      expect(response.body).to match(/Remember me.{0,40}cookie/im)
      expect(response.body).to match(/two weeks/i)
      expect(Devise.remember_for).to eq(2.weeks),
        'Devise.remember_for changed -- update the remember-me lifetime on /privacy'
    end

    it 'discloses the sign-in cookies while warden_hooks.rb sets them' do
      hooks = File.read(Rails.root.join('config/initializers/warden_hooks.rb'))
      skip 'warden_hooks no longer sets cookies' unless hooks.include?('cookies.encrypted')

      expect(response.body).to match(/Two sign-in cookies/i)
    end

    it 'discloses Google Analytics while the layout loads it' do
      tracking = File.read(Rails.root.join('app/views/shared/_tracking.html.erb'))
      skip 'no analytics partial' unless tracking.include?('googletagmanager')

      expect(response.body).to include('Google Analytics')
      expect(response.body).to include('_ga')
    end
  end

  # Every account is admin-created, so users already have a route to the company
  # through their administrator; there is no privacy@ mailbox.
  it 'directs questions to an administrator rather than a mailbox' do
    get privacy_path

    expect(response.body).not_to match(/privacy@/i)
    expect(response.body).to match(/administrator/i)
  end

  # For anyone not signed in, the sign-in page IS the homepage, and Google
  # expects the policy to be linked from it. The layout footer carries the only
  # link; a second one in the view would be a visible duplicate.
  it 'is linked exactly once from the sign-in page' do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    assert_select 'a[href=?]', privacy_path, count: 1
  end
end
