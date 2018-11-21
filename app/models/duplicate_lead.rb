# == Schema Information
#
# Table name: duplicate_leads
#
#  id           :uuid             not null, primary key
#  reference_id :uuid
#  lead_id      :uuid
#

class DuplicateLead < ApplicationRecord
  belongs_to :reference, class_name: 'Lead', foreign_key: 'reference_id'
  belongs_to :lead

  validates :lead_id, uniqueness: { scope: :reference_id }
end
