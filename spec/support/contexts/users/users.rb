RSpec.shared_context "users" do
  include_context "roles"

  let(:default_property) { create(:property) }

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
    default_property.assign_user(user: user, role: 'manager')
    user.reload
    user
  }

  let(:agent) {
    user = create(:user)
    user.role = property_role
    user.save
    user.confirm
    default_property.assign_user(user: user, role: 'agent')
    user.reload
    user
  }

  let(:agent2) {
    user = create(:user)
    user.role = property_role
    user.save
    user.confirm
    user
    another_property = create(:property)
    another_property.assign_user(user: user, role: 'agent')
    user.reload
    user
  }

end
