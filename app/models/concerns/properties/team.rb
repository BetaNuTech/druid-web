module Properties
  module Team
    extend ActiveSupport::Concern

    included do
      belongs_to :team, optional: true
      # TODO: uncomment below and comment agents association in Property model
      #has_many :agents, through: :team, class_name: 'User', source: :users
    end
  end
end
