class Reason < ApplicationRecord
  ALLOWED_PARAMS = [:id, :name, :description,:active]

  validates :name,
    presence: true,
    uniqueness: { case_sensitive: false }

end
