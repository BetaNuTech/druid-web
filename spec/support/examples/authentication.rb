RSpec.shared_examples "authenticated action" do |action_info|
  include_context "users"

  let(:actionname) { action_info[:name].to_sym }
  let(:actionparams) { action_info[:params] }

  it "will redirect if unauthenticated" do
    get actionname, params: actionparams
    expect(response).to redirect_to(new_user_session_path)
  end
end
