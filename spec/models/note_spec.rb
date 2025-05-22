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
#  classification :integer          default("comment")
#

require 'rails_helper'

RSpec.describe Note, type: :model do
  include_context "messaging"

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
      t = DateTime.current
      d = Date.current
      note.schedule = Schedule.new(time: t, date: d)
      note.save!
      expect(note.start_time).to eq(d)
    end

    it "returns notes after a scheduled date" do
      t = DateTime.current
      d = Date.current
      note.schedule = Schedule.new(time: t, date: d)
      note.save!
      expect(Note.with_start_date(d)).to eq([note])
    end

    it "returns 'notable' information" do
      lead = create(:lead)
      note.notable = lead
      note.save!
      expect(note.notable_subject).to match("(Lead)")
      note.notable = note.user
      note.save!
      expect(note.notable_subject(note.user)).to match("Personal Event/Note")
      expect(note.notable_subject).to match("(User)")
      note.notable = nil
      note.save!
      expect(note.notable_subject).to eq("None")
    end
  end

  describe "callbacks" do
    it "should update the Lead's last_comm if the LeadAction is a contact event" do
      # Create a user
      user = create(:user)
      # Create a property
      property = create(:property)
      # Create a lead with the user and property
      lead = create(:lead, user: user, property: property)
      
      original_last_comm = 1.hour.ago.round # Round to ensure to_i comparison is stable
      lead.update_column(:last_comm, original_last_comm)

      # Create a contact lead action
      contact_lead_action = create(:lead_action, is_contact: true)
      
      # Create a scheduled action that connects the lead and the lead_action
      scheduled_action = create(:scheduled_action, target: lead, lead_action: contact_lead_action, user: user)
      
      # Now create the note with the notable as the lead_action
      note = create(:note, notable: contact_lead_action, lead_action: contact_lead_action, user: user)

      lead.reload
      # last_comm should have changed from its original setting
      expect(lead.last_comm.to_i).not_to eq(original_last_comm.to_i)
      # last_comm should be greater than or equal to note.created_at (make_contact uses note.created_at)
      # Allow for slight timing variations by checking a small window or just greater than original
      expect(lead.last_comm.to_i).to be >= note.created_at.to_i - 1 # note.created_at might be a fraction of a sec earlier than last_comm if Time.current is used later
      expect(lead.last_comm.to_i).to be <= note.created_at.to_i + 1 # Accommodate slight differences
      expect(lead.last_comm.to_i).to be > original_last_comm.to_i
    end
  end
end
