module Leads
  module Roommates
    extend ActiveSupport::Concern

    included do
      has_many :roommates, dependent: :destroy
    end

  end
end
