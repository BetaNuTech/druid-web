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

  def self.groups(property: nil)
    references = []
    lead_ids = []
    visited = []
    groups = {}

    property_id = case property
                  when Property
                    property.id
                  when String
                    property
                  else
                    nil
                  end

    all.to_a.each do |record|
      record_arr = [record.reference_id, record.lead_id]
      references << record_arr
      lead_ids << record_arr[0]
      lead_ids << record_arr[1]
    end

    lead_ids.uniq!

    lead_skope = property_id ? Lead.where(property_id: property_id) : Lead
    leads = lead_skope.where(id: lead_ids).
      inject({}){|memo, obj| memo[obj.id] = obj; memo}

    visited = {}
    references.each do |ref|
      if !visited.fetch(ref[1], false)
        groups[ref[0]] ||= []
        groups[ref[0]] << leads[ref[1]]
        visited[ref[0]] = true
        visited[ref[1]] = true
      end
    end

    groups.keys.each do |group|
      if groups[group].compact.empty?
        groups.delete(group)
      else
        groups[group] = groups[group].uniq
      end
    end

    return groups
  end

  def self.groups_annotated(property: nil)#
    # Create array of Lead group arrays sorted by each group's latest Lead created_at, DESC
    return self.groups(property: property).
      to_a.
      map{|g| g[1]}.
      compact.
      sort_by{|g| g.compact.map{|r| r.created_at}.sort.last }.
      reverse.
      map do |g|
        group_indexes = g.compact.map{|lead|
          {
            id: lead.id,
            name: lead.name,
            email: lead.email,
            phone1: lead.phone1,
            phone2: lead.phone2,
            remoteid: lead.remoteid
          }
        }

        g.
          compact.
          # Sort Leads within group by created_at ASC (oldest first)
          sort_by{|r| r.created_at}.
          map do |lead|
            other_records = group_indexes.dup
            other_records.delete_if{|l| l[:id] == lead.id}
            {
              record: lead,
              flags: {
                remoteid: lead.remoteid.present? && other_records.map{|o| o[:remoteid]}.include?(lead.remoteid),
                name: lead.name.present? && other_records.map{|o| o[:name]}.include?(lead.name),
                email: lead.email.present? && other_records.map{|o| o[:email]}.include?(lead.email),
                phone: ( lead.phone1.present? && other_records.map{|o| o[:phone1]}.include?(lead.phone1) ) ||
                ( lead.phone2.present? && other_records.map{|o| o[:phone2]}.include?(lead.phone2) )
              }
            }
          end
      end
  end

  def self.for_property_accessible_by_user(property, user)
    lead_scope = LeadPolicy::Scope.new(user, property.leads).resolve
    return self.where("reference_id IN (#{lead_scope.select(:id).to_sql})")
  end

  def self.cleanup_invalid
    invalid_values_sql = Lead::DUPLICATE_IGNORED_VALUES.map{|v| "'#{v}'"}.join(', ')

    sql_query =<<~SQL
      DELETE FROM duplicate_leads
      WHERE
        duplicate_leads.id IN (
          SELECT duplicate_leads.id
          FROM duplicate_leads
          INNER JOIN leads
            ON (duplicate_leads.reference_id = leads.id OR duplicate_leads.lead_id = leads.id)
          WHERE (
            leads.phone1 IN (#{invalid_values_sql})
            OR leads.phone2 IN (#{invalid_values_sql})
            OR leads.first_name IN (#{invalid_values_sql})
            OR leads.last_name IN (#{invalid_values_sql})
            OR leads.email IN (#{invalid_values_sql})
          )
        )
    SQL

    ActiveRecord::Base.connection.execute(sql_query)
    return true
  end
end
