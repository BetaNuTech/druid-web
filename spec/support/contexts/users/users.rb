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

  let(:operator) {
    user = create(:user)
    user.role = operator_role
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
