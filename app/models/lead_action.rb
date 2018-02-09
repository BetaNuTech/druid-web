class LeadAction < ApplicationRecord
  ALLOWED_PARAMS = [:id, :name, :description, :active]
end
