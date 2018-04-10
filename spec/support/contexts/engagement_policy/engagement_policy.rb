RSpec.shared_context "engagement_policy" do
  let(:seed_reasons) {
    create(:reason, name: 'Scheduled', active: true)
    true
  }

  let(:seed_lead_actions){
    LeadAction.load_seed_data
    true
  }

  let(:seed_engagement_policy) {
    seed_reasons
    seed_lead_actions
    file_path = File.join(Rails.root, "db", "seeds", "engagement_policy.yml")
    loader = EngagementPolicyLoader.new(file_path)
    loader.call
    true
  }

end
