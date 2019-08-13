FactoryBot.define do
  factory :lead_referral do
    lead
    lead_referral_source
    referrable { create(:resident, property: lead.property) }
    note { 'Resident' }
  end
end
