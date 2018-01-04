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

# Users
puts " * Creating Users"
## Admin user
admin_email = 'admin@example.com'
print "   - #{admin_email} "
if User.where(email: admin_email).present?
  puts "[OK]"
else
  admin_password = 'ChangeMeNow'
  admin = User.new(email: admin_email, password: admin_password, password_confirmation: admin_password)
  if admin.save
    puts "(password: '#{admin_password}') [OK]"
  else
    puts "[FAIL] (#{admin.errors.to_a})"
  end
end
