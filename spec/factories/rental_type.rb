FactoryBot.define do
  factory :rental_type do
    sequence :name do |n|
      "Rental Type #{n}"
    end
  end
end
