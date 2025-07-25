RSpec.shared_context "roles" do
  let(:administrator_role) { Role.find_by(slug: 'administrator') || create(:administrator_role) }
  let(:corporate_role) { Role.find_by(slug: 'corporate') || create(:corporate_role) }
  let(:manager_role) { Role.find_by(slug: 'manager') || create(:manager_role) }
  let(:property_role) { Role.find_by(slug: 'property') || create(:property_role) }
  let(:other_role) { Role.find_by(slug: 'other') || create(:other_role)}
end
