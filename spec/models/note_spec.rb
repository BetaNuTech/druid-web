# == Schema Information
#
# Table name: notes
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_action_id :uuid
#  reason_id      :uuid
#  notable_id     :uuid
#  notable_type   :string
#  content        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe Note, type: :model do

  describe "initialization" do
    let(:note) { build(:note) }

    it "can be initialized" do
      expect(note).to be_a(Note)
    end

    it "can be saved" do
      assert note.save
    end
  end

  describe "validations"

  describe "associations" do
    let(:note) { create(:note) }

    it "belongs to a lead action" do
      expect(note.lead_action).to be_a(LeadAction)
    end

    it "belongs to a reason" do
      expect(note.reason).to be_a(Reason)
    end

    it "belongs to a user" do
      expect(note.user).to be_a(User)
    end

    it "returns the schedule start time" do
      t = Time.now
      d = Date.today
      note.schedule = Schedule.new(time: t, date: d)
      note.save!
      expect(note.start_time).to eq(d)
    end

    it "returns notes after a scheduled date" do
      t = Time.now
      d = Date.today
      note.schedule = Schedule.new(time: t, date: d)
      note.save!
      expect(Note.with_start_date(d)).to eq([note])
    end

    it "returns 'notable' information" do
      lead = create(:lead)
      note.notable = lead
      note.save!
      expect(note.notable_subject).to match("(Lead)")
    end
  end
end
