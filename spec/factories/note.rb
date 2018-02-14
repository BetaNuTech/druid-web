# == Schema Information
#
# Table name: notes
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_action_id :uuid
#  reason_id      :uuid
#  notable_type   :string
#  notable_id     :integer
#  content        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
#
FactoryBot.define do
  factory :note do
    user
    lead_action
    reason
    notable { create(:lead) }
    content { Faker::Lorem.paragraph }
  end
end
