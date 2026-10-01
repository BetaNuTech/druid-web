module Leads
  # BlueConnect call leads (LeadSource 'CallCenter') created while
  # CALL_LEAD_GUESTCARD_PUSH_ENABLED is on are handled in Yardi instead of
  # Bluesky: each is queued for Leads::CallGuestcardPusher, which matches the
  # caller to a guest card or creates one for Lea AI, and Bluesky sends the
  # caller no automated messages. See doc/call_lead_guestcard_push.md.
  module CallGuestcards
    extend ActiveSupport::Concern

    CALL_CENTER_SOURCE_SLUG = 'CallCenter'.freeze

    included do
      has_one :call_guestcard_push, dependent: :destroy
      after_create :queue_call_guestcard_push
    end

    def call_center_lead?
      source&.slug == CALL_CENTER_SOURCE_SLUG
    end

    # SMS opt-in requests and welcome emails are skipped for call leads while
    # the push is on: leasing works these callers in Yardi.
    def automated_outreach_suppressed?
      call_center_lead? && Leads::CallGuestcardPusher.enabled?
    end

    private

    def queue_call_guestcard_push
      return unless call_center_lead? && Leads::CallGuestcardPusher.enabled?
      return if property.nil? || property.voyager_property_code.blank?

      CallGuestcardPush.create!(lead: self, property: property, referral: referral,
                                phone: PhoneNumber.format_phone(phone1).presence)
    rescue StandardError => e
      # Never block lead creation over the queue
      Rails.logger.error("Leads::CallGuestcards: could not queue Lead[#{id}] for the Yardi guest card push: #{e}")
    end
  end
end
