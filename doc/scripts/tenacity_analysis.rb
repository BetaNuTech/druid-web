# Tenacity Score Analysis Script
# Usage: 
#   load 'doc/scripts/tenacity_analysis.rb'
#   TenacityAnalysis.new('1002edge').run
#
# For CSV export:
#   TenacityAnalysis.new('1002edge').run(format: :csv)

class TenacityAnalysis
  attr_reader :property_code, :property, :lead_limit

  def initialize(property_code, lead_limit: 10)
    @property_code = property_code
    @lead_limit = lead_limit
    find_property!
  end

  def run(format: :console)
    return puts "Property not found for code: #{property_code}" unless property

    case format
    when :csv
      export_csv
    else
      console_output
    end
  end

  private

  def find_property!
    listing = PropertyListing.active.find_by(code: property_code)
    @property = listing&.property
  end

  def console_output
    puts "\n" + "=" * 60
    puts "TENACITY ANALYSIS FOR #{property.name.upcase}"
    puts "=" * 60
    puts "Property Code: #{property_code}"
    puts "Analysis Date: #{DateTime.current.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "=" * 60

    agents = property.users.active.by_name_asc
    
    if agents.empty?
      puts "\nNo active agents found for this property."
      return
    end

    overall_stats = {
      total_leads: 0,
      total_contacts: 0,
      leads_with_3_plus: 0,
      agents_analyzed: 0
    }

    agents.each do |agent|
      agent_leads = get_reportable_leads_for_agent(agent)
      next if agent_leads.empty?

      overall_stats[:agents_analyzed] += 1
      
      puts "\n" + "-" * 60
      puts "AGENT: #{agent.name} (#{agent.email})"
      puts "-" * 60

      agent_stats = {
        total_tenacity: 0,
        total_contacts: 0,
        leads_with_3_plus: 0
      }

      agent_leads.each_with_index do |lead, index|
        contact_count = lead.contact_events.count
        tenacity_score = lead.tenacity_value
        
        agent_stats[:total_tenacity] += tenacity_score
        agent_stats[:total_contacts] += contact_count
        agent_stats[:leads_with_3_plus] += 1 if contact_count >= 3
        
        overall_stats[:total_leads] += 1
        overall_stats[:total_contacts] += contact_count
        overall_stats[:leads_with_3_plus] += 1 if contact_count >= 3

        puts "\nLead ##{index + 1}: #{lead.name} (ID: #{lead.id})"
        puts "  State: #{lead.state} | Created: #{lead.created_at.strftime('%Y-%m-%d')}"
        puts "  Classification: #{lead.classification || 'lead'}"
        puts "  Tenacity Score: #{tenacity_score.round(1)} (#{contact_count} contact event#{'s' if contact_count != 1})"
        
        if contact_count > 0
          puts "  Contact Events:"
          lead.contact_events.order(:timestamp).each do |event|
            user_name = event.user&.name || 'System'
            
            # Handle SMS messages that have no subject
            description = event.description
            if event.article_type == 'Message' && event.article
              message = event.article
              if message.sms? && description.include?('Outgoing Message: None')
                description = 'Outgoing Message: SMS'
              elsif message.sms? && description.include?('Outgoing Message:')
                # In case subject is nil/empty but not exactly "None"
                subject_part = description.split('Outgoing Message:')[1]&.strip
                if subject_part.nil? || subject_part.empty? || subject_part == 'None'
                  description = 'Outgoing Message: SMS'
                end
              end
            end
            
            puts "    - #{event.timestamp.strftime('%Y-%m-%d %H:%M')}: #{description} [by #{user_name}]"
          end
        end
      end

      # Agent summary
      if agent_leads.any?
        avg_tenacity = agent_stats[:total_tenacity] / agent_leads.count.to_f
        pct_with_3 = (agent_stats[:leads_with_3_plus] / agent_leads.count.to_f * 100)
        
        puts "\n" + "~" * 40
        puts "Summary for #{agent.name}:"
        puts "  Total Leads Analyzed: #{agent_leads.count}"
        puts "  Average Tenacity Score: #{avg_tenacity.round(1)}"
        puts "  Average Contact Events: #{(agent_stats[:total_contacts] / agent_leads.count.to_f).round(1)}"
        puts "  Leads with 3+ contacts: #{agent_stats[:leads_with_3_plus]} (#{pct_with_3.round(0)}%)"
      end
    end

    # Overall summary
    if overall_stats[:total_leads] > 0
      puts "\n" + "=" * 60
      puts "OVERALL PROPERTY SUMMARY"
      puts "=" * 60
      puts "Total Agents Analyzed: #{overall_stats[:agents_analyzed]}"
      puts "Total Leads Analyzed: #{overall_stats[:total_leads]}"
      puts "Average Contact Events per Lead: #{(overall_stats[:total_contacts] / overall_stats[:total_leads].to_f).round(1)}"
      puts "Leads with 3+ contacts: #{overall_stats[:leads_with_3_plus]} (#{(overall_stats[:leads_with_3_plus] / overall_stats[:total_leads].to_f * 100).round(0)}%)"
    else
      puts "\nNo reportable leads found for analysis."
    end

    puts "\n" + "=" * 60
  end

  def export_csv
    require 'csv'
    
    csv_string = CSV.generate do |csv|
      csv << ['Property', 'Property Code', 'Agent Name', 'Agent Email', 'Lead ID', 'Lead Name', 
              'Lead State', 'Lead Classification', 'Created Date', 'Tenacity Score', 
              'Contact Event Count', 'Contact Events Detail']
      
      property.users.active.by_name_asc.each do |agent|
        agent_leads = get_reportable_leads_for_agent(agent)
        
        agent_leads.each do |lead|
          contact_events = lead.contact_events.order(:timestamp)
          events_detail = contact_events.map { |e| 
            "#{e.timestamp.strftime('%Y-%m-%d %H:%M')}: #{e.description}"
          }.join(" | ")
          
          csv << [
            property.name,
            property_code,
            agent.name,
            agent.email,
            lead.id,
            lead.name,
            lead.state,
            lead.classification || 'lead',
            lead.created_at.strftime('%Y-%m-%d'),
            lead.tenacity_value.round(1),
            contact_events.count,
            events_detail
          ]
        end
      end
    end
    
    filename = "tenacity_#{property_code}_#{DateTime.current.strftime('%Y%m%d_%H%M%S')}.csv"
    puts csv_string
    puts "\n# To save this CSV, copy the output above or redirect to a file:"
    puts "# File.write('#{filename}', csv_string)"
  end

  def get_reportable_leads_for_agent(agent)
    # Get leads assigned to this agent that are reportable (valid for tenacity scoring)
    # Reportable means: classification is 'lead' or nil, and state is not resident/exresident/disqualified
    agent.leads
      .where(property: property)
      .where(classification: ['lead', nil])
      .where.not(state: ['resident', 'exresident', 'disqualified'])
      .includes(:contact_events => :user)
      .order(created_at: :desc)
      .limit(lead_limit)
  end
end

# One-liner convenience methods for quick analysis
def analyze_tenacity(property_code, limit: 10)
  TenacityAnalysis.new(property_code, lead_limit: limit).run
end

def export_tenacity_csv(property_code, limit: 10)
  TenacityAnalysis.new(property_code, lead_limit: limit).run(format: :csv)
end

puts "TenacityAnalysis loaded successfully!"
puts "Usage examples:"
puts "  TenacityAnalysis.new('1002edge').run"
puts "  TenacityAnalysis.new('1002edge', lead_limit: 20).run"
puts "  TenacityAnalysis.new('1002edge').run(format: :csv)"
puts "Or use convenience methods:"
puts "  analyze_tenacity('1002edge')"
puts "  export_tenacity_csv('1002edge', limit: 20)"