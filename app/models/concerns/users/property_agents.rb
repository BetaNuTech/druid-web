module Users
  module PropertyAgents
    extend ActiveSupport::Concern

    included do
      has_many :property_agents, dependent: :destroy
      accepts_nested_attributes_for :property_agents, allow_destroy: true, reject_if: ->(attrs){ attrs['property_id'].blank? }
      has_many :properties, through: :property_agents
    end
  end
end
