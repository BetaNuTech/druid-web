# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#

##
# Roles
roles = {
  administrator: "highest level role",
  operator: "system administrator",
  agent: "Agent role"
}
puts " * Creating Roles"
roles.each do |name, description|
  print "   - '#{name}' (slug: #{name}) "
  role = Role.new(name: name.capitalize, slug: name, description: description)
  if role.save
    puts "[OK]".green
  else
    puts "[FAIL] (#{role.errors.to_a})".red
  end
end

##
# Lead Sources
puts " * Creating default Lead Sources"
sources = {
  "druid webapp": {
    name: 'Druid Webapp',
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
    puts "[OK]".green
  else
    puts "[FAIL] (#{source.errors.to_a})".red
  end
end

# Users
puts " * Creating Users"
## Admin user
admin_email = 'admin@example.com'
print "   - #{admin_email} "
admin_password = 'ChangeMeNow'
admin = User.new(email: admin_email, password: admin_password, password_confirmation: admin_password)
if admin.save
  admin.confirm
  admin.role = Role.administrator
  admin.save!
  puts "(password: '#{admin_password}') [OK]".green
else
  puts "[FAIL] (#{admin.errors.to_a})".red
end

# Unit Types
puts " * Creating Unit Types"
unittypes = %w{Residential Commercial}
unittypes.each do |ut_name|
  print "   - #{ut_name} "
  ut = UnitType.new(name: ut_name)
  if ut.save
    puts "[OK]".green
  else
    puts "[FAIL] (#{ut.errors.to_a})".red
  end
end
