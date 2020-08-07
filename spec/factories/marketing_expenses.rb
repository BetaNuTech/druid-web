# == Schema Information
#
# Table name: marketing_expenses
#
#  id                  :uuid             not null, primary key
#  property_id         :uuid             not null
#  marketing_source_id :uuid             not null
#  invoice             :string
#  description         :text
#  fee_total           :decimal(, )      not null
#  fee_type            :integer          default("free"), not null
#  quantity            :integer          default(1), not null
#  start_date          :datetime         not null
#  end_date            :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
FactoryBot.define do
  factory :marketing_expense do
    property { create(:property) }
    marketing_source { create(:marketing_source, property: property) }
    description { Faker::Lorem.sentence }
    fee_total { Faker::Number.decimal(l_digits: 2) }
    fee_type { marketing_source.fee_type }
    quantity { 2 }
    start_date { marketing_source.start_date }
    end_date {  marketing_source.end_date }
  end
end
