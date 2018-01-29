module Leads
  module Search
    extend ActiveSupport::Concern

    included do
      # https://github.com/Casecommons/pg_search
      include PgSearch

      pg_search_scope :search_for,
        against: %i{first_name last_name referral notes phone1 phone2 fax email id_number},
        order_within_rank: "leads.created_at DESC",
        using: { tsearch: { any_word: true } }
    end
  end
end
