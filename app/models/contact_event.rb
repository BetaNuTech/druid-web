# == Schema Information
#
# Table name: contact_events
#
#  id            :uuid             not null, primary key
#  lead_id       :uuid             not null
#  user_id       :uuid             not null
#  article_id    :uuid
#  article_type  :string
#  description   :string
#  timestamp     :datetime         not null
#  first_contact :boolean          default(FALSE), not null
#  lead_time     :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class ContactEvent < ApplicationRecord
  belongs_to :lead
  belongs_to :user
  belongs_to :article, polymorphic: true, required: false

  scope :first_contact, ->() { where(first_contact: true) }
  scope :slow, ->() { where('lead_time > 1440') }
  scope :glacial, ->() { where('lead_time > 5000') }
end
