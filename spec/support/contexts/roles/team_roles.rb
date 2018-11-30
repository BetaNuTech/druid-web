RSpec.shared_context "teamroles" do
  let(:manager_teamrole) { create(:manager_teamrole)}
  let(:lead_teamrole) { create(:lead_teamrole)}
  let(:agent_teamrole) { create(:agent_teamrole)}
  let(:none_teamrole) { create(:none_teamrole)}
end
