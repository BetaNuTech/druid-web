# == Schema Information
#
# Table name: properties
#
#  id                   :uuid             not null, primary key
#  name                 :string
#  address1             :string
#  address2             :string
#  address3             :string
#  city                 :string
#  state                :string
#  zip                  :string
#  country              :string
#  organization         :string
#  contact_name         :string
#  phone                :string
#  fax                  :string
#  email                :string
#  units                :integer
#  notes                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  active               :boolean          default(TRUE)
#  website              :string
#  school_district      :string
#  amenities            :text
#  application_url      :string
#  team_id              :uuid
#  call_lead_generation :boolean          default(TRUE)
#  maintenance_phone    :string
#  working_hours        :jsonb
#  timezone             :string           default("UTC"), not null
#  leasing_phone        :string
#

require 'rails_helper'

RSpec.describe Property, type: :model do
  let(:valid_attributes) {
    attributes_for(:property)
  }

  let(:invalid_attributes) {
    attributes_for(:property, name: nil)
  }

  let(:active_property) {
    create(:property, name: 'Active property', active: true)
  }

  let(:inactive_property) {
    create(:property, name: 'Inactive property', active: false)
  }


  describe "validations" do
    it "requires a name" do
      property = Property.new(valid_attributes)
      assert(property.valid?)

      property.name = nil
      refute(property.valid?)
    end
  end

  describe "scopes" do
    it "can be active" do
      active_property; inactive_property
      expect(Property.count).to eq(2)
      assert(active_property.active)
      refute(inactive_property.active)
      expect(Property.active.count).to eq(1)
    end
  end

  describe "associations" do
    describe "leads" do
      let(:lead1) {
        create(:lead, property_id: active_property.id)
      }

      let(:lead2) {
        create(:lead, property_id: active_property.id)
      }

      before do
        lead1
        lead2
      end

      it "has many leads" do
        active_property.reload
        expect(active_property.leads.count).to eq(2)
        expect(inactive_property.leads.count).to eq(0)
      end

      it "has many unit_types" do
        ut = create(:unit_type, property: active_property)
        active_property.reload
        expect(active_property.unit_types.count).to eq(1)
      end
    end

    describe "listings" do
      let(:listing1) {
        create(:property_listing, property: active_property, code: 'listing1', active: true)
      }

      let(:listing2) {
        create(:property_listing, property: active_property, code: 'listing2', active: false)
      }

      before do
        listing1; listing2
      end

      it "has many listings" do
        active_property.reload
        expect(active_property.listings.count).to eq(2)
        expect(active_property.listings.active.count).to eq(1)
      end

      it "returns missing_listings" do
        expect(active_property.missing_listings.size).to eq(0)

        listing2.destroy
        active_property.reload
        expect(active_property.missing_listings.size).to eq(1)
      end

      it "returns all possible listings" do
        ppl = active_property.present_and_possible_listings
        expect(ppl.size).to eq(2)
        assert(ppl.map{|pl| pl.is_a? PropertyListing}.all?)
        refute(ppl.map(&:new_record?).any?)

        listing2.destroy
        active_property.reload
        ppl = active_property.present_and_possible_listings
        assert(ppl.map(&:new_record?).any?)
      end

      it "handles deleted sources when listing possible listings (inconsistent db state)" do
        listing = active_property.listings.last
        source = listing.source
        source.destroy
        ppl = active_property.present_and_possible_listings
      end

      it "returns the code for a listing" do
        expect(active_property.listing_code(listing1.source)).to eq(listing1.code)
        expect(active_property.listing_code(listing2.source)).to eq(listing2.code)
        expect(active_property.listing_code(nil)).to eq(nil)
      end

    end

    describe "residents" do
      it "has many residents" do
        resident = create(:resident, property: active_property)
        active_property.reload
        expect(resident.property).to eq(active_property)
        expect(active_property.residents).to eq([resident])
      end
    end

    describe "engagement_policies" do
      it "has many engagement_policies" do
        engagement_policy = create(:engagement_policy, property: active_property)
        active_property.reload
        expect(active_property.engagement_policies).to eq([engagement_policy])
      end
    end

    describe :teams do
      include_context "team_members"

      let(:team) { create(:team) }
      let(:property) { create(:property, team: nil) }
      it "should optionally have a team" do
        assert(property.valid?)
        property.team = team
        property.save!
        expect(property.team).to be_a(Team)
      end
    end

    describe "phone numbers" do
      let(:property) { create(:property) }
      let(:phone1) { build(:phone_number) }

      it "should have phone_numbers" do
        property.phone_numbers = [phone1]
        property.save!
        property.reload
        phone1.reload
        expect(property.phone_numbers).to eq([phone1])
      end

      it "should have number variants" do
        property.phone_numbers = [phone1]
        property.save!
        property.reload
        expect(property.number_variants.size).to eq(4)

      end
    end

    describe "users" do
      let(:property) { create(:property) }
      let(:property2) { create(:property) }

      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:user3) { create(:user) }
      let(:user4) { create(:user) }

      before do
        property; property2
        User.destroy_all
        user1; user2; user3; user4
        PropertyUser.destroy_all
      end

      it "has agents" do
        property.assign_user(user: user1, role: 'agent')
        property.assign_user(user: user2, role: 'agent')
        property.assign_user(user: user3, role: 'manager')
        property2.assign_user(user: user4, role: 'manager')
        property.reload
        expect(property.agents.count).to eq(2)
        expect(property.agents.to_a.sort).to eq([user1, user2].sort)
      end

      it "has managers" do
        property.assign_user(user: user1, role: 'manager')
        property.assign_user(user: user2, role: 'manager')
        property.assign_user(user: user3, role: 'agent')
        expect(property.managers.count).to eq(2)
        expect(property.managers.to_a.sort).to eq([user1, user2].sort)
      end

      it "lists users available for assignment" do
        property.assign_user(user: user1, role: 'agent')
        property2.assign_user(user: user2, role: 'agent')
        user3
        user_count = User.count
        #binding.pry
        expect(property.users_available_for_assignment.count).to eq(user_count - 2)
      end
    end

    describe "class methods" do
      describe "find_by_code_and_source" do
        let(:property1) { create(:property) }
        let(:property2) { create(:property) }
        let(:property3) { create(:property) }
        let(:listing1) { create(:property_listing, property: property1) }
        let(:listing2) { create(:property_listing, property: property1) }
        let(:listing3) { create(:property_listing, property: property2) }

        before do
          property1; property2
        end

        it "can be found if the code is the property id" do
          expect(Property.find_by_code_and_source(code: property1.id)).to eq(property1)
        end

        it "can be found if the code is a property listing code" do
          expect(Property.find_by_code_and_source(code: listing1.code, source_id: listing1.source.id)).to eq(property1)
          expect(Property.find_by_code_and_source(code: listing2.code, source_id: listing2.source.id)).to eq(property1)
        end

        it "returns nil if it can't be found by id or property listing code" do
          expect(Property.find_by_code_and_source(code: listing2.code, source_id: nil)).to eq(nil)
        end

        it "returns nil if the source is inactive" do
          expect(Property.find_by_code_and_source(code: listing1.code, source_id: listing1.source.id)).to eq(property1)
          source = listing1.source
          source.active = false
          source.save!
          expect(Property.find_by_code_and_source(code: listing1.code, source_id: listing1.source.id)).to eq(nil)
        end

        it "returns nil if the listing is inactive" do
          expect(Property.find_by_code_and_source(code: listing1.code, source_id: listing1.source.id)).to eq(property1)
          listing1.active = false
          listing1.save!
          expect(Property.find_by_code_and_source(code: listing1.code, source_id: listing1.source.id)).to eq(nil)
        end


      end
    end
  end
end
