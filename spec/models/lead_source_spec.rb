# == Schema Information
#
# Table name: lead_sources
#
#  id         :uuid             not null, primary key
#  name       :string
#  incoming   :boolean
#  slug       :string
#  active     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe LeadSource, type: :model do
  let(:valid_attributes) {
    {
      name: 'test',
      incoming: true,
      slug: 'test',
      active: true
    }
  }

  let(:invalid_attributes) {
    { }
  }

  it "has required fields" do
    l1 = LeadSource.new(valid_attributes)
    l1.validate
    assert(l1.valid?)
    l2 = LeadSource.new({})
    l2.validate
    refute(l2.valid?)
    expect(l2.errors.keys.sort).to eq(valid_attributes.keys.sort)
  end

  it "has leads" do
    lead = create(:lead)
    leadsource = create(:lead_source)
    lead.source = leadsource
    lead.save
    leadsource.reload
    expect(leadsource.leads.find(lead.id)).to eq(lead)
  end

  it "has a unique name" do
    lead1 = create(:lead_source, valid_attributes)
    assert(lead1.valid?)
    lead2 = build(:lead_source, valid_attributes.merge(slug: 'zzz'))
    refute(lead2.valid?)
  end

  it "has a unique slug" do
    lead1 = create(:lead_source, valid_attributes)
    assert(lead1.valid?)
    lead2 = build(:lead_source, valid_attributes.merge(name: 'zzz'))
    refute(lead2.valid?)
  end
end
