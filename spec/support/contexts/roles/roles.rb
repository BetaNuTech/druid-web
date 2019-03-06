RSpec.shared_context "roles" do
  let(:administrator_role) { create(:administrator_role) }
  let(:corporate_role) { create(:corporate_role) }
  let(:manager_role) { create(:manager_role) }
  let(:property_role) { create(:property_role) }
  let(:other_role) { create(:other_role)}
end
