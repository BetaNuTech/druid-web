# == Schema Information
#
# Table name: residents
#
#  id          :uuid             not null, primary key
#  lead_id     :uuid
#  property_id :uuid
#  unit_id     :uuid
#  residentid  :string
#  status      :string
#  dob         :date
#  title       :string
#  first_name  :string
#  middle_name :string
#  last_name   :string
#  address1    :string
#  address2    :string
#  city        :string
#  state       :string
#  zip         :string
#  country     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe Resident, type: :model do
  include_context "users"
  include_context "messaging"

  let(:valid_attributes) { build(:resident).attributes }

  it "can be initialized" do
    resident = Resident.new(valid_attributes)
    expect(resident).to be_a(Resident)
  end

  it "can be created" do
    resident = Resident.new(valid_attributes)
    assert resident.save
  end

  describe "validations" do
    let(:resident) { build(:resident)}
    let(:property) { resident.property }

    it "must have a unit that belongs to the same property" do
      assert resident.valid?
      property2 = create(:property)
      unit = resident.unit
      unit.property = property2
      unit.save!
      resident.unit = unit
      refute resident.valid?
      expect(resident.errors.full_messages.last).to eq(Resident::INVALID_UNIT_PROPERTY_ERROR)
    end

    it "must have a unique residentid" do
      resident2 = create(:resident)
      assert resident.valid?
      resident.residentid = resident2.residentid
      refute resident.valid?
    end

    it "must have a status" do
      assert resident.valid?
      resident.status = "former"
      assert resident.valid?
      resident.status = "invalid status"
      refute resident.valid?
      resident.status = nil
      refute resident.valid?
    end

    it "must have a first_name" do
      assert resident.valid?
      resident.first_name = nil
      refute resident.valid?
    end

    it "must have a last_name" do
      assert resident.valid?
      resident.last_name = nil
      refute resident.valid?
    end
  end

  describe "associations" do
    #it "has a detail (ResidentDetail) which is assigned on initialization" do
      #resident = Resident.new
      #expect(resident.detail).to be_a(ResidentDetail)
    #end

    it "accepts nested attributes for ResidentDetail" do
      params = {
        resident: {
          first_name: "Joe",
          detail_attributes: {
            phone1: "555-555-5555"
          }
        }
      }
      resident = Resident.new
      resident.attributes = params[:resident]
      expect(resident.first_name).to eq(params[:resident][:first_name])
      expect(resident.detail.phone1).to eq(params[:resident][:detail_attributes][:phone1])
    end
  end

  describe "callbacks" do
    it "assigns a random and unique residentid" do
      resident = build(:resident)
      resident.residentid = nil
      resident.save!
      expect(resident.residentid).to_not be_nil
    end
  end

  describe "instance methods" do
    it "returns a full concatenated name" do
      resident = build(:resident)
      expected_name = [resident.title, resident.first_name, resident.middle_name, resident.last_name].join(" ")
      expect(resident.name).to eq(expected_name)
    end

    it "returns a salutation" do
      resident = build(:resident)
      expected_name = [resident.title, resident.last_name].join(" ")
      expect(resident.salutation).to eq(expected_name)
    end
  end

  describe "lead detection" do
    let(:open_lead1) { create(:lead, user: agent, property: agent.property, state: 'open', notes: 'open_lead1') }
    let(:open_lead2) { create(:lead, user: agent, property: agent.property, state: 'open', notes: 'open_lead2') }
    let(:prospect_lead1) { create(:lead, user: agent, property: agent.property, state: 'prospect', notes: 'prospect_lead1') }
    let(:prospect_lead2) { create(:lead, user: agent, property: agent.property, state: 'prospect', notes: 'prospect_lead2') }
    let(:showing_lead) { create(:lead, user: agent, property: agent.property, state: 'showing', notes: 'showing_lead') }
    let(:showing_lead2) { create(:lead, user: agent, property: agent.property, state: 'showing', notes: 'showing_lead2') }
    let(:applicant_lead) { create(:lead, user: agent, property: agent.property, state: 'application', notes: 'applicant_lead') }
    let(:resident_lead) { create(:lead, user: agent, property: agent.property, state: 'resident', notes: 'resident_lead') }
    let(:resident_nolead) { create(:resident, property: agent.property, lead: nil, detail: create(:resident_detail, phone1: '5556667777')) }
    let(:resident_open_lead1) { create(:resident, property: agent.property, lead: nil, first_name: open_lead1.first_name, last_name: open_lead1.last_name, detail: create(:resident_detail, phone1: open_lead1.phone1)) }
    let(:resident_prospect_lead1) { create(:resident, property: agent.property, lead: nil, first_name: prospect_lead1.first_name, last_name: prospect_lead1.last_name, detail: create(:resident_detail, phone1: prospect_lead1.phone1)) }
    let(:resident_showing_lead) { create(:resident, property: agent.property, lead: nil, first_name: showing_lead.first_name, last_name: showing_lead.last_name, detail: create(:resident_detail, phone2: showing_lead.phone2)) }
    let(:resident_applicant_lead) { create(:resident, property: agent.property, lead: nil, first_name: applicant_lead.first_name, last_name: applicant_lead.last_name, detail: create(:resident_detail, email: applicant_lead.email)) }
    let(:resident_resident_lead) { create(:resident, property: agent.property, lead: resident_lead, first_name: resident_lead.first_name, last_name: resident_lead.last_name, detail: create(:resident_detail, email: resident_lead.email)) }
    let(:resident_former_prospect_lead2) { create(:resident, property: agent.property, lead: nil, first_name: prospect_lead2.first_name, last_name: prospect_lead2.last_name, status: 'former', detail: create(:resident_detail, email: prospect_lead2.email)) }
    let(:resident_associated) { create(:resident, property: agent.property, lead: showing_lead2, first_name: showing_lead2.first_name, last_name: showing_lead2.last_name, status: 'former', detail: create(:resident_detail, email: showing_lead2.email)) }

    before(:each) do
      open_lead1
      open_lead2
      showing_lead
      showing_lead2
      applicant_lead
      resident_lead
      resident_nolead
      resident_open_lead1
      resident_prospect_lead1
      resident_showing_lead
      resident_applicant_lead
      resident_resident_lead
      resident_former_prospect_lead2
      resident_associated
    end

    it "should return active leads that correspond to current residents" do
      service = Residents::LeadMatcher.new
      collection = service.matching_active_leads
      expect(collection.count).to eq(3)
      matched_lead_ids = collection.map{|m| m[:lead].id}.sort
      lead_ids = [prospect_lead1.id, applicant_lead.id, showing_lead.id].sort
      expect(matched_lead_ids).to eq(lead_ids)
      collection_ids = collection.map{|m| [m[:lead].id, m[:resident].id] }.sort
      expected_ids = [[prospect_lead1.id, resident_prospect_lead1.id],[showing_lead.id, resident_showing_lead.id],[applicant_lead.id, resident_applicant_lead.id]].sort
      expect(collection_ids).to eq(expected_ids)
    end

    it "should transition active leads that correspond to current residents" do
      expect(resident_nolead.lead).to be_nil
      expect(resident_open_lead1.lead).to be_nil
      expect(resident_prospect_lead1.lead).to eq(nil)
      expect(resident_showing_lead.lead).to eq(nil)
      expect(resident_applicant_lead.lead).to eq(nil)
      expect(resident_resident_lead.lead).to eq(resident_lead)
      expect(resident_former_prospect_lead2.lead).to eq(nil)
      expect(resident_associated.lead).to eq(showing_lead2)

      service = Residents::LeadMatcher.new
      assert service.call

      resident_lead.reload
      resident_nolead.reload
      resident_open_lead1.reload
      resident_prospect_lead1.reload
      resident_showing_lead.reload
      resident_applicant_lead.reload
      resident_resident_lead.reload
      resident_former_prospect_lead2.reload
      resident_associated.reload

      expect(resident_nolead.lead).to be_nil
      expect(resident_open_lead1.lead).to be_nil
      expect(resident_prospect_lead1.lead).to eq(prospect_lead1)
      expect(resident_showing_lead.lead).to eq(showing_lead)
      expect(resident_applicant_lead.lead).to eq(applicant_lead)
      expect(resident_resident_lead.lead).to eq(resident_lead)
      expect(resident_former_prospect_lead2.lead).to eq(nil)
      expect(resident_associated.lead).to eq(showing_lead2)
    end
  end

end
