namespace :marketing_sources do

  desc 'Generate Marketing Sources for Arrowtel integration from Property Numbers'
  task create_from_property_numbers: :environment do

    marketing_numbers = Property.active.map{|p| {property: p, id: p.id, name: p.name, numbers: p.phone_numbers.map{|pn| [pn.name, pn.number]}}}

    marketing_numbers.each do |property_data|
      puts "=== Creating Marketing Sources for #{property_data[:name]}"
      integration_helper = MarketingSources::IncomingIntegrationHelper.new(
        property: property_data[:property],
        integration: LeadSource.where(slug: 'Arrowtel').first
      )
      property_data[:numbers].each do |number_data|
        name, phone = number_data
        attrs = {
          property_id: property_data[:id],
          name: name,
          tracking_number: phone
        }

        if (marketing_source = MarketingSource.where(attrs).first)
          puts "* #{name} is already present."
          next
        else
          new_attrs = integration_helper.new_marketing_source_attributes.
            merge(attrs).
            merge({
              description: "Incoming calls from #{name}",
              active: true,
              start_date: DateTime.now.beginning_of_year,
              fee_type: 'free',
              tracking_number: phone
            })
          marketing_source = MarketingSource.new(new_attrs)
        end

        if marketing_source.save
          puts "* Created #{marketing_source.name} source for #{property_data[:name]}"
        else
          puts "! ERROR creating #{name}: #{marketing_source.errors}"
        end
      end # numbers

    end #properties

    puts "DONE."
  end
end
