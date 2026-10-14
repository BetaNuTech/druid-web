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
    def self.record(property:, stage:, resident:, contact: nil, source: nil, lead: nil)
      return if property.nil?

      text = line(stage: stage, resident: resident, contact: contact, source: source, lead: lead)
      Note.create(notable: property, classification: 'system', content: "#{NOTE_PREFIX} #{text}")
      YodaBotMessageJob.perform_later(channel: channel, text: "#{property.name}: #{text}") if channel
      text
    rescue StandardError => e
      # The block itself already happened; logging must never undo it
      Rails.logger.error("Leads::ResidentBlockLog: #{e.class}: #{e.message}")
      nil
    end

    def self.line(stage:, resident:, contact: nil, source: nil, lead: nil)
      what = [source.presence, 'contact'].compact.join(' ')
      what = "#{what} from #{format_contact(contact)}" if contact.present?
      what += " (Lead #{lead.id})" if lead&.id
      "#{what} #{stage}, matches resident #{describe(resident)}"
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
