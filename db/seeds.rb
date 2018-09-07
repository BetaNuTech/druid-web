# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#

##
# Roles
roles = {
  administrator: "Highest level role",
  corporate: "System Administrator",
  manager: "Property Manager",
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

# Team Roles
roles = {
  manager: 'Property Manager',
  lead: 'Team Lead',
  agent: 'Agent',
  none: 'None'
}
puts " * Creating Team Roles"
roles.each do |name, description|
  print "   - '#{name}' (slug: #{name}) "
  role = Teamrole.new(name: name.capitalize, slug: name, description: description)
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
  },
  "cloudmailin": {
    name: 'Cloudmailin',
    slug: 'Cloudmailin',
    incoming: true,
    active: true
  },
  "yardi_voyager": {
    name: 'YardiVoyager',
    slug: 'YardiVoyager',
    incoming: false,
    active: true
  },
  "costar": {
    name: 'CoStar',
    slug: 'Costar',
    incoming: true,
    active: true
  }
}
sources.each_pair do |source_name, attrs|
  print "   - '#{source_name}' (slug: #{attrs[:slug]}) "
  if (LeadSource.where(slug: attrs[:slug]).any?)
    puts "[OK]".green
    next
  end
  source = LeadSource.new(attrs)
  if source.save
    puts "[OK]".green
  else
    puts "[FAIL] (#{source.errors.to_a})".red
  end
end

# Users
puts " * Creating Users"
if User.count == 0
  ## Admin user
  admin_email = 'admin@example.com'
  print "   - #{admin_email} "
  admin_password = 'ChangeMeNow'
  admin = User.new(email: admin_email, password: admin_password, password_confirmation: admin_password, timezone: 'America/Detroit', profile_attributes: {first_name: 'admin'})
  if admin.save
    admin.confirm
    admin.role = Role.administrator
    admin.save!
    puts "(password: '#{admin_password}') [OK]".green
  else
    puts "[FAIL] (#{admin.errors.to_a})".red
  end
  ## Agent user
  agent_email = 'agent@example.com'
  print "   - #{agent_email} "
  agent_password = 'ChangeMeNow'
  agent = User.new(email: agent_email, password: agent_password, password_confirmation: agent_password)
  if agent.save
    agent.confirm
    agent.role = Role.agent
    agent.save!
    puts "(password: '#{agent_password}') [OK]".green
  else
    puts "[FAIL] (#{agent.errors.to_a})".red
  end
else
  puts 'Aborting, as User accounts are present.'
end


# Rental Types
puts " * Creating Rental Types"
rental_types = %w{Residential Commercial}
rental_types.each do |rt_name|
  print "   - #{rt_name} "
  rt = RentalType.new(name: rt_name)
  if rt.save
    puts "[OK]".green
  else
    puts "[FAIL] (#{rt.errors.to_a})".red
  end
end

puts " * Creating Message Types"
Rake::Task["db:seed:message_types"].invoke
puts " * Creating Message Templates"
Rake::Task["db:seed:message_templates"].invoke
puts " * Creating Properties"
Rake::Task["db:seed:properties"].invoke
puts " * Creating Reasons"
Rake::Task["db:seed:reasons"].invoke
puts " * Creating Lead Actions"
Rake::Task["db:seed:lead_actions"].invoke
puts " * Creating Engagement Policy"
Rake::Task["db:seed:engagement_policy"].invoke
puts ' * Creating Message Delivery Adapters'
Rake::Task["db:seed:message_delivery_adapters"].invoke

