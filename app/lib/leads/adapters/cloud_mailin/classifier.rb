require 'nbayes'

module Leads
  module Adapters
    module CloudMailin
      class Classifier
        FILENAME = File.join(Rails.root, 'app','lib','leads','adapters','cloud_mailin','classifier.yml').freeze

        def initialize
          @lead_source = LeadSource.where(slug: 'Cloudmailin').limit(1).first
          @classifier = NBayes::Base.new
          load_db
        end

        def classify(item)
          data = classification_data(item)
          return false unless data

          @classifier.classify(data)
        end

        def train_historical(start_date: nil, end_date: nil)
          sdate = start_date || 12.months.ago
          edate = end_date || 2.weeks.ago
          puts "*** Training CloudMailin Lead classifier with date between #{sdate} and #{edate}..."

          # Train with Valid Leads from CloudMailin
          puts "*** Training on valid leads"
          valid_leads = valid_leads_for_training(start_date: sdate, end_date: edate)
          puts " - Found #{valid_leads.count} valid Leads to train the classifier"
          valid_leads.find_each do |lead|
            print "." if train_item(classification_data(lead), :lead)
          end
          puts "[OK]"

          # Train with Leads manually disqualified and marked as non-leads
          puts "*** Training on invalid leads"
          invalid_leads = invalid_leads_for_training(start_date: sdate, end_date: edate)
          puts " - Found #{invalid_leads.count} invalid Leads to train the classifier"
          invalid_leads.find_each do |lead|
            print "." if train_item(classification_data(lead), :other)
          end
          puts "[OK]"

          dump_db

          puts "*** Done!"
        end

        def classification_data(item)
          case item
          when Lead
            lead_classification_data(item)
          when String
            item.split(/\s+/)
          else
            false
          end
        end

        private

        def classification_data_filename
          FILENAME
        end

        def lead_classification_data(lead)
          data = JSON.parse(lead.preference.raw_data) rescue nil
          return nil unless data

          header_data = data.fetch('headers', nil)
          envelope_data = data.fetch('envelope', nil)
          return nil unless header_data && envelope_data

          [
            header_data["From"].split(/\s+/),
            header_data["Subject"].split(/\s+/),
            envelope_data["helo_domain"].split(/\s+/)
          ].flatten.compact
        end

        def classification_data_file
          if File.exist?(classification_data_filename)
            File.open(classification_data_filename, 'rb')
          else
            f = File.open(classification_data_filename,'wb')
            f.puts ""
            f.close
            classification_data_file
          end
        end

        def train_item(data, classification)
          return false unless data

          @classifier.train(data, classification)
          true
        end

        def dump_db
          puts "*** Saving training data..."
          @classifier.dump(classification_data_filename)
        end

        def load_db
          @classifier = NBayes::Base.new.load(classification_data_file.read)
        rescue
          @classifier = NBayes::Base.new
        end

        def valid_leads_for_training(start_date:, end_date:)
          Lead.includes(:preference).where(
            state: Leads::StateMachine::IN_PROGRESS_STATES,
            lead_source_id: @lead_source.id,
            classification: [ :lead, nil ],
            created_at: start_date..end_date
          )
        end

        def invalid_leads_for_training(start_date:, end_date:)
          Lead.includes(:preference).where(
            state: [:disqualified],
            lead_source_id: @lead_source.id,
            classification: [:vendor, :resident, :other],
            created_at: start_date..end_date
          )
        end
      end

    end
  end
end
