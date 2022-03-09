require 'rails_helper'

RSpec.describe DuplicateLead do
  include_context "users"
  include_context "messaging"

  let(:lead_name_dup1) { create(:lead, first_name: 'Foobar', last_name: 'Quux', state: 'open') }
  let(:lead_name_dup2) { create(:lead, first_name: 'Foobar', last_name: 'Quux', state: 'open') }
  let(:lead_name_dup3) { create(:lead, first_name: 'Foobar', last_name: 'Quux', state: 'open') }
  let(:lead_phone1_dup1) { create(:lead, phone1: '6555555555', state: 'open') }
  let(:lead_phone1_dup2) { create(:lead, phone1: '6555555555', state: 'open') }
  let(:lead_phone1_dup3) { create(:lead, phone1: '6555555555', state: 'open') }
  let(:lead_phone2_dup1) { create(:lead, phone2: '6555555556', state: 'open') }
  let(:lead_phone2_dup2) { create(:lead, phone2: '6555555556', state: 'open') }
  let(:lead_phone2_dup3) { create(:lead, phone2: '6555555556', state: 'open') }
  let(:lead_email_dup1) { create(:lead, email: 'me1@1here.com', state: 'open') }
  let(:lead_email_dup2) { create(:lead, email: 'me1@1here.com', state: 'open') }
  let(:lead_email_dup3) { create(:lead, email: 'me1@1here.com', state: 'open') }

  describe "duplicate detection" do
    let(:lead1) { create(:lead, state: 'open') }
    let(:lead2) { create(:lead, state: 'open') }

    it "detects dupes by name" do
      lead_name_dup1
      lead_name_dup2
      lead_name_dup3

      dupes = lead_name_dup1.possible_duplicates
      expect(dupes.count).to eq(2)
      expect(dupes.map(&:id).sort).to eq([lead_name_dup2.id, lead_name_dup3.id].sort)
    end

    it "detects dupes by phone1" do
      lead_phone1_dup1
      lead_phone1_dup2
      lead_phone1_dup3

      dupes = lead_phone1_dup1.possible_duplicates
      expect(dupes.count).to eq(2)
      expect(dupes.map(&:id).sort).to eq([lead_phone1_dup2.id, lead_phone1_dup3.id].sort)
    end

    it "detects dupes by phone2" do
      lead_phone2_dup1
      lead_phone2_dup2
      lead_phone2_dup3

      dupes = lead_phone2_dup1.possible_duplicates
      expect(dupes.count).to eq(2)
      expect(dupes.map(&:id).sort).to eq([lead_phone2_dup2.id, lead_phone2_dup3.id].sort)
    end

    it "detects dupes by email" do
      lead_email_dup1
      lead_email_dup2
      lead_email_dup3

      dupes = lead_email_dup1.possible_duplicates
      expect(dupes.count).to eq(2)
      expect(dupes.map(&:id).sort).to eq([lead_email_dup2.id, lead_email_dup3.id].sort)
    end

    describe "record creation" do

      it "marks duplicates on Lead create" do
        lead1
        expect(lead1.duplicates.count).to eq(0)

        lead3 = create(:lead, phone1: lead1.phone1)
        lead1.reload
        lead3.reload

        expect(lead3.duplicates.count).to eq(1)
      end

      it "marks duplicates unless lead.skip_duplicates is set to true" do
        lead1
        expect(lead1.duplicates.count).to eq(0)

        lead3 = build(:lead, phone1: lead1.phone1)
        lead3.skip_dedupe = true
        lead3.save!
        lead1.reload
        lead3.reload
        expect(lead3.duplicates.count).to eq(0)

        lead3.skip_dedupe = nil
        lead1.phone1 = '5555555556'
        lead1.save
        lead3.phone1 = '5555555556'
        lead3.save!
        lead3.reload

        expect(lead3.duplicates.count).to eq(1)
      end

      it "marks duplicates on Lead save" do
        lead1
        lead1.reload
        expect(lead1.duplicates.count).to eq(0)
        lead2
        lead2.reload
        expect(lead2.duplicates.count).to eq(0)

        lead2.phone1 = lead1.phone1
        lead2.save
        lead2.reload
        expect(lead2.duplicates.count).to eq(1)
      end

      it "removes stale DuplicateLead records on Lead update" do
        lead_phone1_dup1
        lead_phone1_dup2
        lead_phone1_dup3
        lead_phone1_dup1.reload
        lead_phone1_dup2.reload
        lead_phone1_dup3.reload

        expect(lead_phone1_dup1.duplicates.count).to eq(2)
        expect(lead_phone1_dup2.duplicates.count).to eq(2)
        expect(lead_phone1_dup2.duplicates.count).to eq(2)

        lead_phone1_dup2.reload
        lead_phone1_dup2.phone1 = '000'
        lead_phone1_dup2.save!
        lead_phone1_dup1.reload
        expect(lead_phone1_dup1.duplicates.count).to eq(1)
      end

      describe "when all existing duplicates are already marked as a duplicate" do
        it "should not classify the latest lead as a duplicate"
      end
      describe "when some duplicates are already marked as a duplicate" do
      end

      describe "spam calls" do
        before(:each) do
          test_strategy = Flipflop::FeatureSet.current.test!
          test_strategy.switch!(:lead_automatic_dedupe, true)
        end
        let(:spam_number) {  '1555556666'} 
        let(:spam_lead) { create(:lead, first_name: 'Test', last_name: 'foo', phone1: spam_number, state: 'disqualified', property_id: agent.property.id, classification: 'spam') }
        it "should disqualify leads matching the phone number of spam leads" do
          spam_lead
          new_lead = create(:lead, first_name: 'Test2', phone1: spam_number, state: 'prospect', property_id: agent.property.id)
          assert(new_lead.auto_disqualify_lead?)
        end
      end

    end
  end

  describe "validations" do
    let(:lead1) { create(:lead)}
    let(:lead2) { create(:lead)}
    it "has a unique lead_id per reference_id" do
      dup1 = DuplicateLead.new(reference: lead1, lead: lead2)
      dup2 = DuplicateLead.new(reference: lead1, lead: lead2)

      assert(dup1.save)
      refute(dup2.save)
    end
  end

  describe "automatic disqualification of leads matching residents" do
    let(:property) { create(:property) }
    let(:matching_first_name1) { 'Firstname' }
    let(:matching_last_name1) { 'Lastname' }
    let(:matching_email1) { 'email1111@example.com' }
    let(:matching_phone1) { 'email1111@example.com' }
    let(:reference_resident0) { create(:resident) }
    let(:reference_resident1) { create(:resident, property: property) }
    let(:reference_resident2) { create(:resident, property: property, first_name: matching_first_name1, last_name: matching_last_name1, detail: build(:resident_detail, email: matching_email1)) }
    let(:matching_lead) { create(:lead, property: property, first_name: matching_first_name1, last_name: matching_last_name1, email: matching_email1, state: 'open')}
    let(:non_matching_lead) { create(:lead, property: property, state: 'open')}

    before :each do
      reference_resident0
      reference_resident1
      reference_resident2
    end

    it "should not automatically disqualify if there are no matches" do
      non_matching_lead
      non_matching_lead.reload
      expect(non_matching_lead.state).to eq('open')
      expect(non_matching_lead.classification).to be_nil
    end

    it "should automatically disqualify leads matching resident records" do
      matching_lead
      matching_lead.reload
      expect(matching_lead.state).to eq('disqualified')
      expect(matching_lead.classification).to eq('resident')
    end

  end

  describe "automatic duplicate disqualification" do
    let(:reference_lead1) { create(:lead, state: 'prospect') } # for matching by email
    let(:reference_lead2) { create(:lead, state: 'prospect') } # for matching by phone
    let(:reference_lead3) { create(:lead, state: 'prospect') } # for (not) matching by name only
    let(:reference_lead4) { # for (not) matching due to age
      lead = create(:lead, state: 'prospect')
      lead.created_at = 5.months.ago
      lead.save!
      lead
    } 
    let(:matching_by_email) { create(:lead, state: 'open', first_name: reference_lead1.first_name, last_name: reference_lead1.last_name, email: reference_lead1.email)}
    let(:matching_by_phone) { create(:lead, state: 'open', first_name: reference_lead2.first_name, last_name: reference_lead2.last_name, phone1: reference_lead2.phone1)}
    let(:match_by_name_only) { create(:lead, state: 'open', first_name: reference_lead3.first_name, last_name: reference_lead3.last_name)}
    let(:miss_by_date) { create(:lead, state: 'open', first_name: reference_lead4.first_name, last_name: reference_lead4.last_name, email: reference_lead4.email)}
    let(:resident_no_match) { create(:resident, property: reference_lead1.property)}
    let(:resident_matching_lead1) {
      create(:resident,
             first_name: reference_lead1.first_name,
             last_name: reference_lead1.last_name,
             email: reference_lead1.email
            )
    }

    before(:each) do
      test_strategy = Flipflop::FeatureSet.current.test!
      test_strategy.switch!(:lead_automatic_dedupe, true)
    end

    describe "when the feature is not enabled" do
      it "should not auto disqualify leads" do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:lead_automatic_dedupe, false)
        reference_lead1; reference_lead2; reference_lead3;
        matching_by_email; matching_by_phone; match_by_name_only
        matching_by_email.reload; matching_by_phone.reload; match_by_name_only.reload

        refute(matching_by_email.disqualified?)
        refute(matching_by_phone.disqualified?)
      end
    end

    describe 'when the feature is enabled' do
      before(:each) do
        test_strategy = Flipflop::FeatureSet.current.test!
        test_strategy.switch!(:lead_automatic_dedupe, true)
      end
      it 'should not disqualify if first or last name is missing' do
        property = default_property
        existing_lead_1 = create(:lead, state: 'prospect', property: property, last_name: nil)
        matching_lead_1 = create(:lead, state: 'open', property: property,
                                 first_name: existing_lead_1.first_name,
                                 last_name: existing_lead_1.last_name,
                                 phone1: existing_lead_1.phone1,
                                 email: existing_lead_1.email)
        existing_lead_1.reload
        matching_lead_1.reload
        refute(matching_lead_1.disqualified?)
      end

      it 'should still disqualify if phone or email is missing' do
        property = default_property
        Lead.destroy_all
        existing_lead_1 = create(:lead, state: 'prospect', property: property)
        existing_lead_1.reload
        matching_lead_1 = create(:lead, state: 'open', property: property,
                                 first_name: existing_lead_1.first_name,
                                 last_name: existing_lead_1.last_name,
                                 email: existing_lead_1.email)
        existing_lead_1.reload
        matching_lead_1.reload

        assert(matching_lead_1.disqualified?)
      end


      it "should not disqualify if all matches are already disqualified" do
        property = default_property
        existing_lead_1 = create(:lead, state: 'prospect', property: property)
        existing_lead_1.reload
        matching_lead_1 = create(:lead, state: 'open', property: property,
                                 first_name: existing_lead_1.first_name,
                                 last_name: existing_lead_1.last_name,
                                 email: existing_lead_1.email)
        matching_lead_2 = create(:lead, state: 'open', property: property,
                                 first_name: existing_lead_1.first_name,
                                 last_name: existing_lead_1.last_name,
                                 phone1: existing_lead_1.phone1)
        existing_lead_1.reload
        matching_lead_1.reload
        matching_lead_2.reload
        assert(matching_lead_1.disqualified?)
        assert(matching_lead_2.disqualified?)
      end

      it "should not disqualify if there is an newer in-progress match" do
        property = default_property
        existing_lead_1 = create(:lead, state: 'disqualified', property: property)
        matching_lead_1 = create(:lead, state: 'open', property: property,
                                 first_name: existing_lead_1.first_name,
                                 last_name: existing_lead_1.last_name,
                                 phone1: existing_lead_1.phone1,
                                 email: existing_lead_1.email)
        matching_lead_2 = create(:lead, state: 'prospect', property: property,
                                 first_name: existing_lead_1.first_name,
                                 last_name: existing_lead_1.last_name,
                                 phone1: existing_lead_1.phone1,
                                 email: existing_lead_1.email)
        existing_lead_1.reload
        matching_lead_1.reload
        matching_lead_2.reload
        refute(matching_lead_1.auto_disqualify_lead?)
      end

      it "should disqualify if there is an older in-progress match" do
        property = default_property
        Lead.destroy_all
        existing_lead_1 = create(:lead, state: 'disqualified', property: property)
        existing_lead_1.reload
        matching_lead_1 = create(:lead, state: 'prospect', property: property,
                                 first_name: existing_lead_1.first_name,
                                 last_name: existing_lead_1.last_name,
                                 phone1: existing_lead_1.phone1,
                                 email: existing_lead_1.email)
        matching_lead_2 = create(:lead, state: 'open', property: property,
                                 first_name: existing_lead_1.first_name,
                                 last_name: existing_lead_1.last_name,
                                 phone1: existing_lead_1.phone1,
                                 email: existing_lead_1.email)
        existing_lead_1.reload
        matching_lead_1.reload
        matching_lead_2.reload

        assert(matching_lead_2.disqualified?)
      end


      it "should automatically disqualify full matches" do
        Lead.destroy_all
        reference_lead1; reference_lead2; reference_lead3;
        matching_by_email; matching_by_phone; match_by_name_only
        matching_by_email.reload; matching_by_phone.reload; match_by_name_only.reload

        assert(matching_by_email.disqualified?)
        assert(matching_by_phone.disqualified?)
        refute(match_by_name_only.disqualified?)
        refute(miss_by_date.disqualified?)
      end
    end


    describe 'resident matching leads helpers' do
      before(:each) do
        @property1 = create(:property)
        @resident1 = create(:resident, property: @property1, detail: build(:resident_detail))
        @lead1 = create(:lead, state: 'open', property: @property1)
        @lead2 = create(:lead, state: 'open', property: @property1, first_name: @resident1.first_name, last_name: @resident1.last_name, email: @resident1.detail.email)

        @property2 = create(:property)
        @resident2 = create(:resident, property: @property2, detail: build(:resident_detail))
        @lead3 = create(:lead, state: 'open', property: @property2)
        @lead4 = create(:lead, state: 'open',  property: @property2, first_name: @resident2.first_name, last_name: @resident2.last_name, phone1: @resident2.detail.phone1)
      end

      it "should disqualify all open leads matching residents" do
        @lead1.reload; @lead2.reload; @lead3.reload; @lead4.reload
        #@lead2.state = 'open'; @lead2.save
        #@lead4.state = 'open'; @lead4.save

        Lead.disqualify_open_resident_leads

        refute(@lead1.disqualified?)
        assert(@lead2.disqualified?)
        refute(@lead3.disqualified?)
        assert(@lead4.disqualified?)
      end

      it 'should report possible resident leads in a csv document' do
        Lead.open_possible_residents_csv
      end
    end

  end
end
