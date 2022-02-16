require 'rails_helper'

RSpec.describe Lead, type: :model do

  include_context "lead_creator"
  include_context "messaging"

  let(:valid_lead_attributes) { valid_lead_creator_attributes }

  let(:valid_lead_attributes_with_valid_token) {
    {
      data: FactoryBot.attributes_for(:lead),
      token: default_lead_source.api_token,
      agent: nil
    }
  }

  let(:valid_lead_attributes_with_valid_property) {
    # valid_lead_attributes_with_valid_token with property_id present
    # in the [:data] Hash of attributes
    valid_lead_attributes_with_valid_token.
      merge(data: valid_lead_attributes_with_valid_token[:data].
                    merge({ property_id: lead_creator_property_listing.code }))
  }

  let(:valid_lead_attributes_with_invalid_token) {
    {
      data: FactoryBot.attributes_for(:lead),
      token: 'bad_token',
      agent: nil
    }
  }

  let(:invalid_lead_attributes) {
    {
      data: FactoryBot.attributes_for(:lead).merge(first_name: nil, last_name: nil),
      token: default_lead_source.api_token,
      agent: nil
    }
  }

  let(:invalid_lead_attributes_with_valid_token) {
    {
      data: FactoryBot.attributes_for(:lead).merge(first_name: nil),
      token: default_lead_source.api_token,
      agent: nil
    }
  }

  let(:invalid_lead_preference_attributes) {
    {
      data: FactoryBot.attributes_for(:lead).
        merge(preference_attributes: {max_area: 100, min_area: 1000}),
      token: default_lead_source.api_token,
      agent: nil
    }
  }

  let(:invalid_source_attributes) {
    {
      data: FactoryBot.attributes_for(:lead),
      token: 'invalid token',
      agent: nil
    }
  }

  let(:missing_token_attributes) {
    {
      data: FactoryBot.attributes_for(:lead),
      token: nil,
      agent: nil
    }
  }

  before do
    lead_creator_property_listing
  end

  it "can be initialized with valid data and the BlueSky adapter" do
    creator = Leads::Creator.new(**valid_lead_attributes)
    expect(creator.source).to be_a(LeadSource)
    expect(creator.parser).to eq(Leads::Adapters::Bluesky)
    lead = creator.call
    refute(creator.errors.any?)
    assert(lead.valid?)
    expect(creator.lead).to eq(lead)
    expect(Lead.last).to eq(lead)
  end

  it "can create a lead with a default source" do
    attrs = valid_lead_attributes
    attrs.delete(:source)
    creator = Leads::Creator.new(**valid_lead_attributes)
    expect(creator.source).to be_a(LeadSource)
    lead = creator.call
    refute(creator.errors.any?)
    assert(lead.valid?)
    expect(creator.lead).to eq(lead)
    expect(Lead.last).to eq(lead)
  end

  it "will create a Lead with the agent assigned" do
    attrs = valid_lead_attributes.merge({agent: agent})
    creator = Leads::Creator.new(**attrs)
    lead = creator.call
    expect(lead.user).to eq(agent)
  end

  it "can be initialized with an invalid source" do
    creator = Leads::Creator.new(**invalid_source_attributes)
    expect(creator.source).to be_nil
    expect(creator.parser).to be_nil
    expect{creator.call}.to_not change{Lead.count}
    assert(creator.call.errors.any?)
    expect(creator.errors.messages[:base].first).to match('Invalid Access Token')
    expect(creator.lead).to be_a(Lead)
    assert(creator.lead.errors.any?)
  end

  it "can be initialized with a missing token" do
    creator = Leads::Creator.new(**invalid_source_attributes)
    expect(creator.source).to be_nil
    expect(creator.parser).to be_nil
    expect{creator.call}.to_not change{Lead.count}
    assert(creator.call.errors.any?)
    expect(creator.errors.messages[:base].first).to match('Invalid Access Token')
    expect(creator.lead).to be_a(Lead)
    assert(creator.lead.errors.any?)
  end

  it "can be initialized with an invalid source parser" do
    default_lead_source.slug = 'Foobar'
    default_lead_source.save!
    creator = Leads::Creator.new(**valid_lead_attributes)
    expect(creator.source).to eq(default_lead_source)
    expect(creator.parser).to be_nil
    expect{creator.call}.to_not change{Lead.count}
    assert(creator.call.errors.any?)
    expect(creator.errors.messages[:base].first).to match('Parser for Lead Source not found')
    expect(creator.lead).to be_a(Lead)
    assert(creator.lead.errors.any?)
  end

  it "can be initialized with invalid lead attributes" do
    creator = Leads::Creator.new(**invalid_lead_attributes)
    lead = creator.call
    assert(lead.errors.any?)
    assert(creator.errors.any?)
    expect(creator.lead).to eq(lead)
  end

  it "can be initialized with invalid lead preference attributes" do
    creator = Leads::Creator.new(**invalid_lead_preference_attributes)
    lead = creator.call
    assert(lead.errors.any?)
    assert(creator.errors.any?)
    expect(creator.lead).to eq(lead)
  end

  describe "when initialized with a token" do
    it "will create a lead with valid attributes and source if the token matches the source token" do
      creator = Leads::Creator.new(**valid_lead_attributes_with_valid_token)
      expect(creator.source).to be_a(LeadSource)
      expect(creator.parser).to eq(Leads::Adapters::Bluesky)
      lead = creator.call
      refute(creator.errors.any?)
      assert(lead.valid?)
      expect(creator.lead).to eq(lead)
      expect(Lead.last).to eq(lead)
    end

    it "will fail to create a lead with invalid attributes and valid source if the token matches the source token" do
      creator = Leads::Creator.new(**invalid_lead_attributes_with_valid_token)
      lead = creator.call
      assert(lead.errors.any?)
      assert(creator.errors.any?)
      expect(creator.lead).to eq(lead)
    end

    it "will fail to create a lead with valid attributes and valid source if the token doesn't match the source token" do
      creator = Leads::Creator.new(**valid_lead_attributes_with_invalid_token)
      expect(creator.source).to be_nil
      expect(creator.parser).to be_nil
      lead = nil
      expect {
        lead = creator.call
      }.to_not change(Lead, :count)
      assert(lead.errors.any?)
      assert(creator.errors.any?)
    end

    it "will have the property set if the property param is provided" do
      creator = Leads::Creator.new(**valid_lead_attributes_with_valid_token)
      lead = creator.call
    end

    it "will create a lead associated with the provided listing property code" do
      creator = Leads::Creator.new(**valid_lead_attributes_with_valid_property)
      lead = creator.call
      assert(lead.valid?)
      expect(lead.property).to eq(lead_creator_property)
    end
  end

  describe "handling incoming phone leads" do
    let(:resident_duplicate_phone) { '5555551111'}
    let(:lead_duplicate_phone) { '5555551122'}
    let(:lead_unique_phone) { '5555556666'}
    let(:lead_unique_email) { 'unique1@example.com'}
    let(:resident1) {
      resident = create(:resident, detail: create(:resident_detail, phone1: resident_duplicate_phone))
      resident.reload
      resident.detail.phone1 = resident_duplicate_phone
      resident.detail.save!
      resident.reload
      resident
    }
    let(:resident2) { create(:resident, detail: create(:resident_detail)) }
    let(:old_lead1) { create(:lead, phone1: lead_duplicate_phone) }
    let(:old_lead2) { create(:lead) }
    let(:unique_lead_data) {
      { first_name: 'Joe', last_name: 'Doe', phone1: lead_unique_phone, email: lead_unique_email, property_id: resident1.property_id }
    }
    let(:duplicate_lead_data_resident_phone) {
      { first_name: 'Joe', last_name: 'Doe', phone1: resident_duplicate_phone, property_id: resident1.property_id}
    }
    let(:duplicate_lead_data_lead_phone) {
      { first_name: 'Joe', last_name: 'Doe', phone1: lead_duplicate_phone, property_id: resident1.property_id}
    }


    before(:each) do
      call_center_lead_source
      resident1
      resident2
      old_lead1
      old_lead2
      create(:property_listing, source_id: call_center_lead_source.id, property_id: resident1.property_id, code: resident1.property_id)
    end

    describe "when the lead phone matches a resident" do
      it "should fail to create a lead" do
        service = Leads::Creator.new(data: duplicate_lead_data_resident_phone, token: call_center_lead_source.api_token)
        lead = service.call
        refute(lead.save)
      end
    end

    describe "when the lead phone matches another lead" do
      it "should fail to create the lead" do
        service = Leads::Creator.new(data: duplicate_lead_data_lead_phone, token: call_center_lead_source.api_token)
        lead = service.call
        refute(lead.save)
      end
    end
    describe "with an unknown phone number" do
      it "creates a lead" do
        service = Leads::Creator.new(data: unique_lead_data, token: call_center_lead_source.api_token) 
        lead = service.call
        assert(lead.save)
      end
    end
  end
end

