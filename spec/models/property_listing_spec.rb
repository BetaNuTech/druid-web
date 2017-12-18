# == Schema Information
#
# Table name: property_listings
#
#  id          :uuid             not null, primary key
#  code        :string
#  description :string
#  property_id :uuid
#  source_id   :uuid
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe PropertyListing, type: :model do
  let(:property_listing) {
    create(:property_listing)
  }

  let(:valid_attributes) {
    attributes_for(:property_listing)
  }

  describe "validations" do
    describe "code" do
      let(:code1) { 'code1' }
      let(:code2) { 'code2' }

      it "is required" do
        listing = PropertyListing.new(valid_attributes)
        listing.validate
        puts listing.errors.to_a
        assert(listing.valid?)
        listing.code = nil
        refute(listing.valid?)
      end

      it "must be unique" do
        listing1 = create(:property_listing, code: code1)
        listing2 = build(:property_listing, code: code1)
        listing2.validate
        refute(listing2.valid?)

        listing2.code = code2
        assert(listing2.valid?)
      end
    end

    describe "source" do
      let(:source1) {
        create(:lead_source)
      }
      let(:source2) {
        create(:lead_source)
      }

      let(:property1) {
        create(:property)
      }

      let(:property2) {
        create(:property)
      }

      let(:listing1) {
        create(:property_listing, source: source1, property: property1)
      }

      it "should be unique per propery" do
        listing1
        listing = build(:property_listing, source: source1, property: property1)
        listing.validate
        refute(listing.valid?)
        listing.property = property2
        assert(listing.valid?)
      end
    end
  end

  describe "associations" do
    it "has a property" do

    end
  end

  describe "scopes" do
    let(:active_listing) {
      create(:property_listing, active: true)
    }

    let(:inactive_listing) {
      create(:property_listing, active: false)
    }


    it "has an active scope" do
      active_listing; inactive_listing
      expect(PropertyListing.count).to eq(2)
      expect(PropertyListing.active.count).to eq(1)
      expect(PropertyListing.active.first).to eq(active_listing)
    end
  end
end
