# == Schema Information
#
# Table name: message_types
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :text
#  active      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :message_type do
    sequence :name do |n|
      "Message Type #{n}"
    end
    description Faker::Lorem.sentence
    active true

    factory :sms_message_type do
      name "SMS"
      description "SMS"
    end

    factory :email_message_type do
      name "Email"
      description "Email"
    end
  end


end