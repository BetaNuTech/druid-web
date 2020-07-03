namespace :property do

  desc "Portal Data"
  task :portal_data => :environment do
    include ActionView::Helpers

    data = Property.active.all.inject({}) do |memo, property|
      slug = ( Leads::Adapters::YardiVoyager.property_code(property) rescue '' )
      if slug.present?
        memo[slug.to_sym] = {
          name: property.name,
          address: ( property.address || '').gsub(/\n/,', '),
          phone: number_to_phone(property.phone||''),
          website: property.website,
          max_bedrooms: ( property.unit_types.maximum(:bedrooms) || 3),
          max_bathrooms: ( property.unit_types.maximum(:bathrooms) || 3),
          slug: slug
        }
        memo
      else
        memo
      end
    end

    js_doc = <<~JS
    const property_data = #{data.to_json};

    module.exports = {
      property_data: property_data
    }
JS

    filename = 'tmp/portal_property_data.js'
    f = File.open(filename,'wb'){|f| f.puts js_doc}

    puts "= Wrote #{filename}"
  end
end
