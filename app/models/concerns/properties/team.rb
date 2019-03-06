module Properties
  module Team
    extend ActiveSupport::Concern

    included do
      belongs_to :team, optional: true

    end
  end
end
