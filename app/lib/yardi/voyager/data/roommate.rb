module Yardi
  module Voyager
    module Data
      class Roommate
        require 'nokogiri'

        ATTRIBUTES = [
          :record_type,
          :property_id, :prospect_id, :third_party_id,
          :name_prefix, :first_name, :middle_name, :last_name,
          :address1, :address2, :city, :state, :postalcode,
          :email,
          :phones,
          :preference_comment,
          :events,
          :first_comm,
          :responsible_for_lease,
        ]

        attr_accessor *ATTRIBUTES
        attr_accessor :debug

        def self.from_roommate(roommate)
          property_id = Leads::Adapters::YardiVoyager.property_code(roommate&.lead&.property)
          return nil unless property_id.present?

          record = Yardi::Voyager::Data::Roommate.new

          record.property_id = property_id
          #record.prospect_id = nil
          record.third_party_id = roommate.short_id

          if roommate.guarantor?
            record.record_type = 'guarantor'
          elsif roommate.spouse?
            record.record_type = 'spouse'
          elsif roommate.child?
            record.record_type = 'other'
          else
            record.record_type = 'roommate'
          end

          record.first_name = roommate.first_name
          record.last_name = roommate.last_name
          record.email = roomate.email
          record.phones = [ [roomate.phone, 'cell'] ]
          record.preference_comment = roommate.notes
          record.first_comm = roommate.lead.first_comm
          record.responsible_for_lease = roommate.responsible?
          record.events = []

          return record
        end

      end
    end
  end
end
