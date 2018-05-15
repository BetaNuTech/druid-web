FactoryBot.define do
  factory :message_template do
    message_type { create(:message_type)}
    name { Faker::Lorem.sentence }
    subject "Lead Name {{lead_name}}"
    body "Lead Name: {{lead_name}}; Lead Floorplan {{lead_floorplan}}; Agent Name: {{agent_name}}; Agent Title {{agent_title}}; Property Name {{property_name}}; Property City: {{property_city}}; Property Amenities: {{property_amenities}}; Property Website: {{property_website}}; Property Phone: {{property_phone}}"
  end
end
