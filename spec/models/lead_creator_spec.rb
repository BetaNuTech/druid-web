require 'rails_helper'

RSpec.describe Lead, type: :model do
  let(:valid_attributes) {
    {
      data: FactoryBot.attributes_for(:lead),
      source: 'Druid',
      agent: nil
    }
  }

  let(:invalid_lead_attributes) {
    {
      data: FactoryBot.attributes_for(:lead).merge(first_name: nil),
      source: 'Druid',
      agent: nil
    }
  }

  let(:invalid_lead_preference_attributes) {
    {
      data: FactoryBot.attributes_for(:lead).
        merge(preference_attributes: {max_area: 100, min_area: 1000}),
      source: 'Druid',
      agent: nil
    }
  }

  let(:invalid_source_attributes) {
    {
      data: FactoryBot.attributes_for(:lead),
      source: 'Foobar',
      agent: nil
    }
  }

  before do
    create(:lead_source, slug: 'Druid')
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
end

