require 'rails_helper'

RSpec.describe DuplicateLead do

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
    end
  end

  describe "grouping" do
    it "groups duplicates for reporting"
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

end
