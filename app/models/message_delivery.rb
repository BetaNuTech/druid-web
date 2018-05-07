# == Schema Information
#
# Table name: message_deliveries
#
#  id              :uuid             not null, primary key
#  message_id      :uuid
#  message_type_id :uuid
#  attempt         :integer
#  attempted_at    :datetime
#  status          :string
#  log             :text
#  delivered_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class MessageDelivery < ApplicationRecord
end
