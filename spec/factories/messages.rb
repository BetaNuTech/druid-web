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
#  message_type_id     :uuid
#  threadid            :string
#  read_at             :datetime
#  read_by_user_id     :uuid
#

FactoryBot.define do
  factory :message do
    messageable { create(:lead) }
    message_type { MessageType.email || create(:email_message_type) }
    user { create(:user) }
    state { 'draft' }
    senderid { Faker::Internet.email }
    recipientid { Faker::Internet.email }
    message_template { create(:message_template)}
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
    read_at { nil }
    read_by_user_id { nil }
  end
end
