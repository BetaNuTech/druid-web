RSpec.shared_context 'residents' do
  let(:property1_resident1) { create(:resident, property: default_property)}
  let(:lead_referral_source) { create(:lead_referral_source, name: 'Resident') }
  let(:lead) { create(:lead, property: property1_resident1.property, referral: nil) }
  let(:referral_note) { 'Test referral'}
  let(:valid_lead_attributes_with_valid_referral) {
    {
      id: lead.to_param,
      lead: {
        referral: lead_referral_source.name,
        referrals_attributes: [
          {
            lead_referral_source_id: lead_referral_source.id,
            referrable_id: property1_resident1.id,
            referrable_type: 'Resident',
            note: referral_note
          }
        ]
      }
    }
  }

  let(:valid_lead_attributes_with_invalid_referral) {
    {
      id: lead.to_param,
      lead: {
        referral: lead_referral_source.name,
        referrals_attributes: [
          {
            referrable_id: property1_resident1.id,
            referrable_type: 'Resident',
            lead_referral_source_id: nil,
            note: nil
          }
        ]
      }
    }
  }
end
