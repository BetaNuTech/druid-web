module Leads
  module Classifier
    class Trainer
      require 'classifier-reborn'
      require 'base64' 

      VERSION = '1.0' 
      CATEGORIES = %w{lead vendor spam}
      SAMPLE_SIZE = 10000
      SAMPLE_SOURCE = 'Cloudmailin'
      TEST_SAMPLE_SIZE = 100
      SAMPLE_START_DATE = 6 # months ago
      BATCH_SIZE = 500
      CLASSIFIER_DATAFILE = File.join(Rails.root, "tmp/lead_classifier-#{VERSION}.dat")
      EXCLUDE_PROPERTIES = [ 'Summercrest' ]

      def initialize(debug: false, datafile: CLASSIFIER_DATAFILE)
        @classifier = nil
        @debug = debug
        @datafile = datafile
        @sample_source = LeadSource.where(slug: SAMPLE_SOURCE).first
        @sample_start_date = 6.months.ago

        if defined?(EXCLUDE_PROPERTIES)
          @exclude_properties = Property.where(name: EXCLUDE_PROPERTIES).pluck(:id)
        else
          @exclude_properties = []
        end
      end

      def call
        load_classifier
        train
        save_classifier
      end

      def test_lead(lead)
        lead = Lead.find(lead) if lead.is_a?(String)
        puts "*** Testing classifier on Lead[#{lead.id}]: #{lead.name}"
        classification = classifier.classify(classifier_content(lead)).downcase
        success = lead.classification == classification
        result = success ? 'OK' : 'Fail'
        puts " - [#{result}] #{lead.classification}(Lead), #{classification}(predicted)"
      end

      def test
        sample = Lead.includes(:preference).
                  where(classification: CATEGORIES, lead_source_id: @sample_source.id).
                  where(property_id: @exclude_properties).
                  where.not(lead_preferences: {raw_data: nil}).
                  order('RANDOM()').
                  limit(TEST_SAMPLE_SIZE)

        print "*** Testing lead classifier on #{sample.count} records"
        results = {ok: 0, fail: 0}
        failures = []

        sample.each do |lead|
          classification = classifier.classify(classifier_content(lead)).downcase
          if classification == lead.classification
            results[:ok] = results[:ok] + 1
          else
            results[:fail] = results[:fail] + 1
            failures << [classification, lead.id, lead.classification]
          end
          print '.'
        end
        puts "DONE"

        if failures.any?
          failures.each do |failure|
            puts "#{failure[1]} #{failure[2]} != #{failure[0]} (predicted)"
          end
        end

        rate = (results[:ok].to_f / TEST_SAMPLE_SIZE.to_f).round(3)
        puts " * OK: #{results[:ok]}"
        puts " * Failed: #{results[:fail]}"
        puts " * Accuracy: #{rate}"
        true
      end

      private

      def classifier
        @classifier || load_classifier
      end

      def train
        skope = Lead.includes(:preference).
                  where(created_at: SAMPLE_START_DATE.months.ago..).
                  where(classification: CATEGORIES, lead_source_id: @sample_source.id).
                  where.not(property_id: @exclude_properties).
                  order('RANDOM()').
                  limit(SAMPLE_SIZE)

        print "*** Training classifier on #{skope.count} leads"

        skope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
          batch.each do |lead|
            next unless lead&.preference&.raw_data.present?

            classifier.train(lead.classification, classifier_content(lead))
            print '.' if @debug
          end
        end
        puts "DONE training using #{skope.count} leads" if @debug

        test if @debug
      end

      def classifier_content(lead)
        return nil unless ( data = lead.preference.raw_data ).present?

        data = JSON.load(data)
        #data['headers']['From'] + data['headers']['Subject']
        data['headers']['From'] +
          data['headers']['Subject'] +
          ( data['html'] || data['plain'] )
      end

      def save_classifier
        print "*** Preparing classifier data..." if @debug
        data = Base64.encode64(Marshal.dump(@classifier))
        puts "OK" if @debug
        print "*** Saving classifier data..." if @debug
        File.open(@datafile, 'wb') do |f|
          f.write data
        end
        puts "OK" if @debug

        true
      end

      def load_classifier
        if File.exist?(@datafile)
          print '*** Loading classifier data...' if @debug
          @classifier = Marshal.load(Base64.decode64(File.read(@datafile)))
          puts "OK" if @debug
        else
          print '*** Initializing new classifier' if @debug
          @classifier = ClassifierReborn::Bayes.new(categories: CATEGORIES)
          puts "OK" if @debug
        end
        @classifier
      end

    end
  end
end
