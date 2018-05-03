# == Schema Information
#
# Table name: messages
#
#  id                  :uuid             not null, primary key
#  messageable_id      :uuid
#  messageable_type    :string
#  user_id             :uuid             not null
#  state               :string           default("draft"), not null
#  senderid            :string           not null
#  recipientid         :string           not null
#  message_template_id :uuid
#  subject             :string           not null
#  body                :text             not null
#  delivered_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

FactoryBot.define do
  factory :message do
    messageable { create(:lead) }
    user { create(:user) }
    state { 'draft' }
    senderid { Faker::Internet.email }
    recipientid { Faker::Internet.email }
    message_template { create(:message_template)}
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    delivered_at { Faker::Date.between(3.days.ago, Date.today)}
  end
end
