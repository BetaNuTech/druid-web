# == Schema Information
#
# Table name: call_guestcard_pushes
#
#  id                :uuid             not null, primary key
#  lead_id           :uuid             not null
#  property_id       :uuid             not null
#  phone             :string
#  referral          :string
#  status            :string           default("pending"), not null
#  yardi_prospect_id :string
#  yardi_source      :string
#  source_fix_status :string
#  attempts          :integer          default(0), not null
#  last_error        :text
#  resolved_at       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

# A BlueConnect call lead queued for (or resolved by) Leads::CallGuestcardPusher.
# See doc/call_lead_guestcard_push.md.
class CallGuestcardPush < ApplicationRecord
  PENDING = 'pending'.freeze
  CREATED = 'created'.freeze                           # new Admin guest card pushed
  LINKED_NEW_CARD = 'linked_new_card'.freeze           # card made for this call (usually Lea AI)
  LINKED_EXISTING_CARD = 'linked_existing_card'.freeze # caller already had a card
  REPEAT_CALL = 'repeat_call'.freeze                   # same caller resolved within 48h
  DUPLICATE_LEAD = 'duplicate_lead'.freeze             # another lead here already links the caller's card
  RESIDENT = 'resident'.freeze                         # caller is a current Yardi resident
  SKIPPED_NOT_OPEN = 'skipped_not_open'.freeze         # Bluesky already closed the lead
  SKIPPED_NO_PHONE = 'skipped_no_phone'.freeze
  FAILED = 'failed'.freeze

  STATUSES = [PENDING, CREATED, LINKED_NEW_CARD, LINKED_EXISTING_CARD, REPEAT_CALL, DUPLICATE_LEAD,
              RESIDENT, SKIPPED_NOT_OPEN, SKIPPED_NO_PHONE, FAILED].freeze

  # The pusher owns the Yardi guest card for leads in these statuses, so the
  # legacy Yardi sync (Properties::YardiVoyager) never creates, updates or
  # cancels a card for them - even after the switch is turned off.
  YARDI_OWNED_STATUSES = [CREATED, LINKED_NEW_CARD, LINKED_EXISTING_CARD, REPEAT_CALL, DUPLICATE_LEAD, RESIDENT].freeze

  belongs_to :lead
  belongs_to :property

  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: PENDING) }
  scope :yardi_owned, -> { where(status: YARDI_OWNED_STATUSES) }

  def pending?
    status == PENDING
  end
end
