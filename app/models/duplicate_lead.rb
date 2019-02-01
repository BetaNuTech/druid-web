# == Schema Information
#
# Table name: duplicate_leads
#
#  id           :uuid             not null, primary key
#  reference_id :uuid
#  lead_id      :uuid
#

class DuplicateLead < ApplicationRecord
  belongs_to :reference, class_name: 'Lead', foreign_key: 'reference_id'
  belongs_to :lead

  validates :lead_id, uniqueness: { scope: :reference_id }

  def self.groups
    references = []
    lead_ids = []
    visited = []
    groups = {}

    all.to_a.each do |record|
      record_arr = [record.reference_id, record.lead_id]
      references << record_arr
      lead_ids << record_arr[0]
      lead_ids << record_arr[1]
    end

    lead_ids.uniq!
    leads = Lead.where(id: lead_ids).
      inject({}){|memo, obj| memo[obj.id] = obj; memo}

    lead_ids.each do |lead_id|
      visited << lead_id
      matching_references = references.select{|refs| refs[0] == lead_id}
      next unless matching_references.size > 0
      groups[lead_id] ||= []
      matching_references.each do |matches|
        matches.each do |match|
          next if visited.include?(match)
          groups[lead_id] << leads[match]
          visited << match
        end
      end
      if groups[lead_id].size > 0
        groups[lead_id] << leads[lead_id]
      else
        groups.delete(lead_id)
      end
    end

    return groups
  end

  def self.groups_annotated
    # Create array of Lead group arrays sorted by each group's latest Lead created_at, DESC
    processed = self.groups.to_a.
      map{|g| g[1]}.
      sort_by{|g| g.map{|r| r.created_at}.sort.last }.reverse

    # Annotate records to create an array of arrays of Hashes,
    #   flagging duplicate matching keys' match status
    processed = processed.map do |g|
      group_indexes = g.map{|lead|
        {
          id: lead.id,
          name: lead.name,
          email: lead.email,
          phone1: lead.phone1,
          phone2: lead.phone2
        }
      }

      g.
        # Sort Leads within group by created_at DESC
        sort_by{|r| r.created_at}.reverse.
        map do |lead|
          other_records = group_indexes.dup
          other_records.delete_if{|l| l[:id] == lead.id}
          {
            record: lead,
            flags: {
              name: lead.name.present? && other_records.map{|o| o[:name]}.include?(lead.name),
              email: lead.email.present? && other_records.map{|o| o[:email]}.include?(lead.email),
              phone: ( lead.phone1.present? && other_records.map{|o| o[:phone1]}.include?(lead.phone1) ) ||
              ( lead.phone2.present? && other_records.map{|o| o[:phone2]}.include?(lead.phone2) )
            }
          }
        end
    end

    return processed
  end

  def self.for_property_accessible_by_user(property, user)
    lead_scope = LeadPolicy::Scope.new(user, property.leads).resolve
    return self.where(reference_id: lead_scope.select(:id).map(&:id))
  end
end
