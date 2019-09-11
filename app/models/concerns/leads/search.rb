module Leads
  module Search
    extend ActiveSupport::Concern

    included do
      # https://github.com/Casecommons/pg_search
      include PgSearch::Model

      pg_search_scope :search_for,
        against: %i{first_name last_name referral notes phone1 phone2 fax email id_number},
        #against: {
          #last_name: 'A',
          #id_number: 'A',
          #phone1: 'A',
          #first_name: 'B',
          #notes: 'B',
          #phone2: 'B',
          #email: 'C',
          #referral: 'C',
          #fax: 'C'
        #},
        order_within_rank: "leads.created_at DESC",
        using: { tsearch: { any_word: true } }
    end
  end
end
