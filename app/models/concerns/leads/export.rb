module Leads
  module Export
    extend ActiveSupport::Concern

    included do

      CSV_COLUMNS = [
        [ "Yardi Property ID" , -> (lead) { Leads::Adapters::YardiVoyager.property_code(lead.property) } ],
        [ "Property" , -> (lead) { lead.property.try(:name) } ],
        [ "Last Name" , -> (lead) { lead.last_name } ],
        [ "First Name" , -> (lead) { lead.first_name } ],
        [ "Created" , -> (lead) { lead.created_at } ],
        [ "First Contact" , -> (lead) { lead.first_comm } ],
        [ "Last Contact" , -> (lead) { lead.last_comm } ],
        [ "Referral" , -> (lead) { lead.referral } ],
        [ "Email" , -> (lead) { lead.email } ],
        [ "Phone" , -> (lead) { lead.phone1 } ],
        [ "Move-In Date" , -> (lead) { lead.preference.try(:move_in) } ],
        [ "Yardi?" , -> (lead) { lead.remoteid.present? } ],
        [ "Yardi ID" , -> (lead) { lead.remoteid } ],
        [ "Notes" , -> (lead) { lead.preference.try(:notes) } ],
        [ "State" , -> (lead) { lead.state }],
        [ "Classification" , -> (lead) { lead.classification }],
        [ "Bluesky ID" , -> (lead) { lead.id }],
        [ "Bluesky URL" , -> (lead) {
          "%s://%s/leads/%s" % [ ENV['APPLICATION_PROTOCOL'], ENV['APPLICATION_HOST'], lead.id ] }
        ]
      ]

      def to_csv
        CSV.generate_line(
          CSV_COLUMNS.map{|col| col[1].call(self) }
        )
      end
    end

    class_methods do
      CSV_EXPORT_LIMIT = 1000

      def export_csv(search: nil, ids: [])
        case search
        when 'Property'
          skope = Lead.where(property_id: ids)
        when 'Lead', nil
          skope = self
        end

        # Eager load all associations used in CSV generation to prevent N+1 queries
        skope = skope.includes(:property, preference: :unit_type)

        # Limit export to prevent memory issues
        total_count = skope.count
        skope = skope.limit(CSV_EXPORT_LIMIT)

        return CSV.generate do |csv|
          # Add warning if results are limited
          if total_count > CSV_EXPORT_LIMIT
            csv << ["WARNING: Results limited to #{CSV_EXPORT_LIMIT} of #{total_count} total leads"]
          end

          csv << CSV_COLUMNS.map{|col| col[0] }
          skope.find_each(batch_size: 100) do |lead|
            csv << CSV_COLUMNS.map{|col| col[1].call(lead) }
          end
        end
      end
    end

  end
end
