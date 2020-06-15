# == Schema Information
#
# Table name: message_types
#
#  id          :uuid             not null, primary key
#  name        :string           not null
#  description :text
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  html        :boolean          default(FALSE)
#

FactoryBot.define do
  factory :message_type do
    sequence :name do |n|
      "Message Type #{n}"
    end
    description { Faker::Lorem.sentence }
    active { true }

    factory :sms_message_type do
      name { "SMS" }
      description { "SMS" }
      html { false }
      active { true }
    end

    factory :email_message_type do
      name { "Email" }
      description { "Email" }
      html { true }
      active { true }
    end
  end


end
