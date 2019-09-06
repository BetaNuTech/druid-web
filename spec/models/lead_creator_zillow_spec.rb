require 'rails_helper'

RSpec.describe Leads::Adapters::Zillow do
  let(:source) { create(:lead_source, slug: Leads::Adapters::Zillow::LEAD_SOURCE_SLUG) }
  let(:property) { create(:property) }
  let(:listing) { create(:property_listing, source_id: source.id, property_id: property.id) }

  let(:valid_data) {
    {
      data: {
        listingId: listing.code,
        name: 'Rachel',
        email: 'rachel@gmail.com',
        phone: '555-555-8378',
        movingDate: '20160926',
        numBedroomsSought: '3',
        numBathroomsSought: '2',
        message: 'Looking for spacious 3 bedroom apartment or house',
        listingStreet: 'Hayward Park Avenue',
        listingUnit: 'C102',
        listingCity: 'Sunnyvale ',
        listingPostalCode: '94086',
        listingState: 'CA',
        listingContactEmail: 'propertymanager@HaywardParkApartments.com',
        neighborhoods: '["Park Merced", "Sunset"]',
        propertyTypesDesired: '["apartment", "house", "townhouse"]',
        leaseLengthMonths: '12',
        introduction: 'Hello my name is Rachel',
        smoker: 'false',
        parkingTypeDesired: 'required',
        incomeYearly: '150000',
        creditScoreRangeJson: '{"creditScoreMin":675,"creditScoreMax":690}',
        movingFromCity: 'San Francisco',
        movingFromState: 'California',
        moveInTimeframe: 'asap',
        reasonForMoving: 'high rent',
        employmentStatus: 'employed',
        jobTitle: 'Software Engineer',
        employer: 'Zillow',
        employmentStartDate: '2015-09-27',
        employmentDetailsJson: '[{"jobTitle":"Software Engineer","employer":"Google","startDate":"2012-07-21","endDate":"2015-09-20"}]',
        petDetailsJson: '[{"type":"dog","breed":"Lab","size":"huge","weightPounds":50,"description":"Really awesome lab"},{"type":"cat","size":"small","description":"Really annoying cat"}]'
      },
      token: source.api_token
    }
  }

  let(:invalid_data) {
    d = valid_data
    d[:data][:email] = nil
    d[:data][:name] = nil
    d[:data][:email] = nil
    d[:data][:phone] = nil

    d
  }

  before do
    listing
  end

  it "should be a supported source" do
    assert(Leads::Adapters.supported_source?(source.slug))
  end

  it "should create a lead with valid data" do
    creator = Leads::Creator.new(**valid_data)
    expect(creator.source).to be_a(LeadSource)
    lead = creator.call
    refute(creator.errors.any?)
    assert(lead.valid?)
    expect(creator.lead).to eq(lead)
    created_lead = Lead.last
    expect(created_lead).to eq(lead)
    expect(created_lead.property).to eq(property)
  end

  it "should not create a lead if data is invalid" do
    creator = Leads::Creator.new(**invalid_data)
    expect(creator.source).to be_a(LeadSource)
    lead = nil
    expect {
      lead = creator.call
    }.to_not change{Lead.count}
    assert(creator.errors.any?)
    refute(lead.valid?)
  end

end
