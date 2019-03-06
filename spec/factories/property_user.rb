FactoryBot.define do
  factory :property_user do
    user { create(:user) }
    property { create(:property) }
    role { 0 }
  end
end
