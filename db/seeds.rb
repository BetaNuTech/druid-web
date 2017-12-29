# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#

##
# Lead Sources
puts " * Creating default Lead Sources"
sources = {
  "druid webapp": {
    name: 'druid webapp',
    slug: 'Druid',
    incoming: true,
    active: true
  },
  "zillow": {
    name: 'Zillow',
    slug: 'Zillow',
    incoming: true,
    active: true
  }
}
sources.each_pair do |source_name, attrs|
  print "   - '#{source_name}' (slug: #{attrs[:slug]}) "
  source = LeadSource.new(attrs)
  if source.save
    puts "[OK]"
  else
    puts "[FAIL] (#{source.errors.to_a})"
  end
end

