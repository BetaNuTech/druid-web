# Script to list recent Cloudmailin and BlueConnect leads
# Usage: heroku run rails runner lib/tasks/list_recent_leads.rb -a druid-prod

# Find lead sources
cloudmailin_source = LeadSource.find_by(slug: 'Cloudmailin')
blueconnect_source = LeadSource.find_by(slug: 'CallCenter') # BlueConnect uses CallCenter source

puts "\n" + "="*80
puts "RECENT LEADS REPORT - Generated at: #{Time.current}"
puts "="*80

# Helper method to format lead info
def format_lead(lead)
  source_name = lead.source&.name || 'Unknown'
  created_at = lead.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')
  
  info = []
  info << "URL: https://www.blue-sky.app/leads/#{lead.id}.html"
  info << "Created: #{created_at}"
  info << "Name: #{lead.first_name} #{lead.last_name}".strip
  info << "Phone: #{lead.phone1 || 'N/A'}"
  info << "Email: #{lead.email || 'N/A'}"
  info << "State: #{lead.state || 'N/A'}"
  info << "Source: #{source_name}"
  info << "Referral: #{lead.referral || 'N/A'}"
  info << "Property: #{lead.property&.name || 'Not Assigned'}"
  
  info.join(" | ")
end

# Cloudmailin Leads
puts "\nCLOUDMAILIN LEADS (Last 25):"
puts "-"*80

if cloudmailin_source
  cloudmailin_leads = Lead.includes(:source, :property)
                          .where(lead_source_id: cloudmailin_source.id)
                          .order(created_at: :desc)
                          .limit(25)
  
  if cloudmailin_leads.any?
    cloudmailin_leads.each_with_index do |lead, index|
      puts "#{index + 1}. #{format_lead(lead)}"
    end
  else
    puts "No Cloudmailin leads found."
  end
else
  puts "Cloudmailin lead source not found in database."
end

# BlueConnect (CallCenter) Leads
puts "\n\nBLUECONNECT LEADS (Last 25):"
puts "-"*80

if blueconnect_source
  blueconnect_leads = Lead.includes(:source, :property)
                           .where(lead_source_id: blueconnect_source.id)
                           .order(created_at: :desc)
                           .limit(25)
  
  if blueconnect_leads.any?
    blueconnect_leads.each_with_index do |lead, index|
      puts "#{index + 1}. #{format_lead(lead)}"
    end
  else
    puts "No BlueConnect (CallCenter) leads found."
  end
else
  puts "BlueConnect (CallCenter) lead source not found in database."
end

# Summary statistics
puts "\n\nSUMMARY:"
puts "-"*80

if cloudmailin_source
  cloudmailin_total = Lead.where(lead_source_id: cloudmailin_source.id).count
  cloudmailin_today = Lead.where(lead_source_id: cloudmailin_source.id)
                           .where('created_at >= ?', Time.current.beginning_of_day)
                           .count
  puts "Total Cloudmailin leads: #{cloudmailin_total} (#{cloudmailin_today} today)"
end

if blueconnect_source
  blueconnect_total = Lead.where(lead_source_id: blueconnect_source.id).count
  blueconnect_today = Lead.where(lead_source_id: blueconnect_source.id)
                            .where('created_at >= ?', Time.current.beginning_of_day)
                            .count
  puts "Total BlueConnect leads: #{blueconnect_total} (#{blueconnect_today} today)"
end

puts "="*80