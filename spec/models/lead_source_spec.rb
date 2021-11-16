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
  include_context "messaging"

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

  it "automatically generates an api token on create" do
    lead1 = create(:lead_source, api_token: nil)
    lead2 = create(:lead_source, name: 'source2', slug: 'source2', api_token: nil)
    expect(lead1.api_token).to_not be_nil
    expect(lead1.api_token).not_to eq(lead2.api_token)
  end

  describe "listings" do
    let(:property1) { create(:property, name: 'Foobar')}
    let(:property2) { create(:property, name: 'Quux')}
    let(:property3) { create(:property, name: 'Acme')}
    let(:lead_source) { create(:lead_source)}
    let(:listings) {
      [
        create(:property_listing, property: property1, source: lead_source),
        create(:property_listing, property: property2, source: lead_source),
        create(:property_listing, property: property3, source: lead_source),
      ]
    }

    before do
      listings
    end

    it "returns listings by property name" do
      expected_property_names = Property.all.map(&:name).sort
      expect(lead_source.listings_by_property_name.map{|l| l.property.name}).to eq(expected_property_names)
    end

    it "deletes all listings when deleted" do
      expect{lead_source.destroy}.to change{PropertyListing.count}.by(-3)
    end

    it "identifies as a phone source" do
      slug1 = 'CallCenter'
      slug2 = 'Other'
      source1 = LeadSource.where(slug: slug1).first || create(:lead_source, slug: slug1)
      source2 = LeadSource.where(slug: slug2).first || create(:lead_source, slug: slug2)

      assert(source1.phone_source?)
      refute(source2.phone_source?)
    end
  end
end
