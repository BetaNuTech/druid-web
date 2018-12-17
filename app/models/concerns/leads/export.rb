module Leads
  module Export
    extend ActiveSupport::Concern

    included do

      CSV_COLUMNS = [
        [ "Property" , -> (lead) { lead.property.try(:name) } ],
        [ "Last Name" , -> (lead) { lead.last_name } ],
        [ "First Name" , -> (lead) { lead.first_name } ],
        [ "Last Name" , -> (lead) { lead.last_name } ],
        [ "Created" , -> (lead) { lead.created_at } ],
        [ "Referral" , -> (lead) { lead.referral } ],
        [ "Email" , -> (lead) { lead.email } ],
        [ "Phone" , -> (lead) { lead.phone1 } ],
        [ "Yardi?" , -> (lead) { lead.remoteid.present? } ],
        [ "Yardi ID" , -> (lead) { lead.remoteid } ],
        [ "Notes" , -> (lead) { lead.preference.try(:notes) } ]
      ]

      def to_csv
        CSV.generate_line(
          CSV_COLUMNS.map{|col| col[1].call(self) }
        )
      end
    end

    class_methods do
      def export_csv(search: nil, ids: [])
        case search
        when 'Property'
          skope = Lead.where(property_id: ids)
        when 'Lead', nil
          skope = Lead
        end

        skope = skope.includes(:preference, :property)

        return CSV.generate do |csv|
          csv << CSV_COLUMNS.map{|col| col[0] }
          skope.all.each do |lead|
            csv << CSV_COLUMNS.map{|col| col[1].call(lead) }
          end
        end
      end
    end

  end
end