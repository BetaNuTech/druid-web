# == Schema Information
#
# Table name: user_impressions
#
#  id         :uuid             not null, primary key
#  user_id    :uuid
#  reference  :string
#  path       :string
#  referrer   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class UserImpression < ApplicationRecord
  belongs_to :user
  validates :reference, presence: true
end
