module Leads
  # The record of every contact Bluesky refused to treat as a prospect
  # because it belongs to a current Yardi resident. Each block becomes a
  # system note on the property (listed on the property page) and one line
  # in Slack (#bluesky-resident-blocks via Yoda Bot, when
  # RESIDENT_BLOCK_SLACK_CHANNEL is set). See doc/yardi_resident_check.md.
  #
  # Stages, in the order a contact meets them:
  #   rejected on arrival         Leads::Creator: no lead was created
  #   closed after creation       Leads::Duplicates: lead invalidated seconds after creation
  #   closed before the Yardi push  Leads::YardiResidentGate / call push: lead invalidated, no card
  #   held before the Yardi push    gate: lead left to its agent, no card
  class ResidentBlockLog
    CHANNEL_ENV = 'RESIDENT_BLOCK_SLACK_CHANNEL'.freeze
    NOTE_PREFIX = 'Resident block:'.freeze

    def self.channel(env = ENV)
      env[CHANNEL_ENV].to_s.strip.presence
    end

    # resident: a Yardi::Backup::Database::Resident, a ::Resident, or a
    # String already describing the match. contact: the phone/email matched.
    # source: the LeadSource (or its name). referral: the lead's referral,
    # i.e. the marketing source name; a call's tracking number is looked up
    # from it ("to (615) 555-0100 (Google Business Profile)").
    def self.record(property:, stage:, resident:, contact: nil, source: nil, referral: nil, lead: nil)
      return if property.nil?

      text = line(stage: stage, resident: resident, contact: contact, source: source, lead: lead,
                  marketing: marketing_label(property, referral))
      Note.create(notable: property, classification: 'system', content: "#{NOTE_PREFIX} #{text}")
      YodaBotMessageJob.perform_later(channel: channel, text: "#{property.name}: #{text}") if channel
      text
    rescue StandardError => e
      # The block itself already happened; logging must never undo it
      Rails.logger.error("Leads::ResidentBlockLog: #{e.class}: #{e.message}")
      nil
    end

    # e.g. "BlueConnect call to (615) 555-0100 (Google Business Profile), from (256) 263-6836, rejected on arrival, matches resident ..."
    def self.line(stage:, resident:, contact: nil, source: nil, lead: nil, marketing: nil)
      parts = [source_label(source)]
      parts << "to #{marketing}" if marketing.present?
      parts << "from #{format_contact(contact)}#{lead&.id ? " (Lead #{lead.id})" : ''}" if contact.present?
      "#{parts.join(', ')}, #{stage}, matches resident #{describe(resident)}"
    end

    def self.source_label(source)
      name = source.respond_to?(:name) ? source.name : source.to_s
      slug = source.respond_to?(:slug) ? source.slug : nil
      return 'BlueConnect call' if slug == Leads::CallGuestcards::CALL_CENTER_SOURCE_SLUG || name == Leads::CallGuestcards::CALL_CENTER_SOURCE_SLUG

      name.present? ? "#{name} contact" : 'contact'
    end

    # "(615) 555-0100 (Google Business Profile)" when the referral names a
    # marketing source with a tracking number; otherwise just the referral
    def self.marketing_label(property, referral)
      return nil if referral.blank?

      number = property.marketing_sources.find_by(name: referral)&.tracking_number
      number.present? ? "#{format_contact(number)} (#{referral})" : referral
    end

    def self.describe(resident)
      case resident
      when String then resident
      when ::Resident
        who = "#{resident.relationship.presence || 'Tenant'} #{resident.residentid}"
        "#{resident.name}, unit #{resident.unit_label}, #{resident.yardi_status.presence || resident.status} (#{who})"
      else
        resident.respond_to?(:description) ? resident.description : resident.to_s
      end
    end

    def self.format_contact(contact)
      return contact.to_s if contact.to_s.include?('@')

      digits = PhoneNumber.format_phone(contact)
      return contact.to_s if digits.length != 10

      "(#{digits[0, 3]}) #{digits[3, 3]}-#{digits[6, 4]}"
    end
  end
end
