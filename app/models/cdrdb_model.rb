class CdrdbModel < ActiveRecord::Base
  self.abstract_class = true
  establish_connection ENV.fetch('CDRDB_URL','') unless Rails.env.test?
end
