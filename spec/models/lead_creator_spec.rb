require 'rails_helper'

RSpec.describe Lead, type: :model do

  let(:source) { create(:lead_source, slug: LeadSource::DEFAULT_SLUG) }
  let(:property) { create(:property) }
  let(:listing) { create(:property_listing, source_id: source.id, property_id: property.id) }

  let(:valid_attributes) {
    {
      data: FactoryBot.attributes_for(:lead),
      source: source.slug,
      validate_token: source.api_token,
      agent: nil
    }
  }

  let(:valid_attributes_with_valid_token) {
    {
      data: FactoryBot.attributes_for(:lead),
      source: source.slug,
      validate_token: source.api_token,
      agent: nil
    }
  }

  let(:valid_attributes_with_valid_property) {
    # valid_attributes_with_valid_token with property_id present
    # in the [:data] Hash of attributes
    valid_attributes_with_valid_token.
      merge(data: valid_attributes_with_valid_token[:data].
                    merge({ property_id: listing.code }))
  }

  let(:valid_attributes_with_invalid_token) {
    {
      data: FactoryBot.attributes_for(:lead),
      source: source.slug,
      validate_token: 'bad_token',
      agent: nil
    }
  }

  let(:invalid_lead_attributes) {
    {
      data: FactoryBot.attributes_for(:lead).merge(first_name: nil),
      source: source.slug,
      validate_token: source.api_token,
      agent: nil
    }
  }

  let(:invalid_lead_attributes_with_valid_token) {
    {
      data: FactoryBot.attributes_for(:lead).merge(first_name: nil),
      source: source.slug,
      validate_token: source.api_token,
      agent: nil
    }
  }

  let(:invalid_lead_preference_attributes) {
    {
      data: FactoryBot.attributes_for(:lead).
        merge(preference_attributes: {max_area: 100, min_area: 1000}),
      source: source.slug,
      validate_token: source.api_token,
      agent: nil
    }
  }

  let(:invalid_source_attributes) {
    {
      data: FactoryBot.attributes_for(:lead),
      source: 'Foobar',
      validate_token: 'invalid token',
      agent: nil
    }
  }

  before do
    listing
  end

  it "can be initialized with valid data and the Druid adapter" do
    creator = Leads::Creator.new(**valid_attributes)
    expect(creator.source).to be_a(LeadSource)
    expect(creator.parser).to eq(Leads::Adapters::Druid)
    lead = creator.execute
    refute(creator.errors.any?)
    assert(lead.valid?)
    expect(creator.lead).to eq(lead)
    expect(Lead.last).to eq(lead)
  end

  it "can create a lead with a default source" do
    attrs = valid_attributes
    attrs.delete(:source)
    creator = Leads::Creator.new(**valid_attributes)
    expect(creator.source).to be_a(LeadSource)
    lead = creator.execute
    refute(creator.errors.any?)
    assert(lead.valid?)
    expect(creator.lead).to eq(lead)
    expect(Lead.last).to eq(lead)
  end

  it "can be initialized with an invalid source" do
    creator = Leads::Creator.new(**invalid_source_attributes)
    expect(creator.source).to be_nil
    expect(creator.parser).to be_nil
    expect{creator.execute}.to_not change{Lead.count}
    assert(creator.execute.errors.any?)
    expect(creator.errors.messages[:base].first).to match('Lead Source not found')
    expect(creator.lead).to be_a(Lead)
    assert(creator.lead.errors.any?)
  end

  it "can be initialized with invalid lead attributes" do
    creator = Leads::Creator.new(**invalid_lead_attributes)
    lead = creator.execute
    assert(lead.errors.any?)
    assert(creator.errors.any?)
    expect(creator.lead).to eq(lead)
  end

  it "can be initialized with invalid lead preference attributes" do
    creator = Leads::Creator.new(**invalid_lead_preference_attributes)
    lead = creator.execute
    assert(lead.errors.any?)
    assert(creator.errors.any?)
    expect(creator.lead).to eq(lead)
  end

  describe "when initialized with a token" do
    it "will create a lead with valid attributes and source if the token matches the source token" do
      creator = Leads::Creator.new(**valid_attributes_with_valid_token)
      expect(creator.source).to be_a(LeadSource)
      expect(creator.parser).to eq(Leads::Adapters::Druid)
      lead = creator.execute
      refute(creator.errors.any?)
      assert(lead.valid?)
      expect(creator.lead).to eq(lead)
      expect(Lead.last).to eq(lead)
    end

    it "will fail to create a lead with invalid attributes and valid source if the token matches the source token" do
      creator = Leads::Creator.new(**invalid_lead_attributes_with_valid_token)
      lead = creator.execute
      assert(lead.errors.any?)
      assert(creator.errors.any?)
      expect(creator.lead).to eq(lead)
    end

    it "will fail to create a lead with valid attributes and valid source if the token doesn't match the source token" do
      creator = Leads::Creator.new(**valid_attributes_with_invalid_token)
      expect(creator.source).to be_nil
      expect(creator.parser).to be_nil
      lead = nil
      expect {
        lead = creator.execute
      }.to_not change(Lead, :count)
      assert(lead.errors.any?)
      assert(creator.errors.any?)
    end

    it "will have the property set if the property param is provided" do
      creator = Leads::Creator.new(**valid_attributes_with_valid_token)
      lead = creator.execute
    end

    it "will create a lead associated with the provided listing property code" do
      creator = Leads::Creator.new(**valid_attributes_with_valid_property)
      lead = creator.execute
      assert(lead.valid?)
      expect(lead.property).to eq(property)
    end
  end
end

