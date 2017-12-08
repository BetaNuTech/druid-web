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
#  api_token  :string
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
    required_fields = [:name, :slug]
    l1 = LeadSource.new(valid_attributes)
    l1.validate
    assert(l1.valid?)
    l2 = LeadSource.new({})
    l2.validate
    refute(l2.valid?)
    expect(l2.errors.keys.sort).to eq(required_fields.sort)
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

  it "automatically generates an api token on create" do
    lead1 = create(:lead_source, api_token: nil)
    lead2 = create(:lead_source, name: 'source2', slug: 'source2', api_token: nil)
    expect(lead1.api_token).to_not be_nil
    expect(lead1.api_token).not_to eq(lead2.api_token)
  end
end
