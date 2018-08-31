RSpec.shared_context "users" do
  include_context "roles"

  let(:unroled_user) {
    user = create(:user)
    user.save
    user.confirm
    user
  }

  let(:administrator) {
    user = create(:user)
    user.role = administrator_role
    user.save
    user.confirm
    user
  }

  let(:corporate) {
    user = create(:user)
    user.role = corporate_role
    user.save
    user.confirm
    user
  }

  let(:manager) {
    user = create(:user)
    user.role = manager_role
    user.save
    user.confirm
    user
  }

  let(:agent) {
    user = create(:user)
    user.role = agent_role
    user.save
    user.confirm
    user
  }

  let(:agent2) {
    user = create(:user)
    user.role = agent_role
    user.save
    user.confirm
    user
  }

end
