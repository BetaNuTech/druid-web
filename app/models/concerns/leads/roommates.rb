module Leads
  module Roommates
    extend ActiveSupport::Concern

    included do
      has_many :roommates
    end

  end
end
