module Residents
  module Adapters
    class YardiVoyager
      attr_reader :property, :property_code

      def self.sync(properties=nil, debug=false)
        # Handle nil Argument
        active_properties = Property.active
        if properties&.first.is_a?(String)
          # Handle Array of Property codes
          active_properties = properties.map{|propertyid| Leads::Adapters::YardiVoyager.property(propertyid) }
        elsif properties&.first.is_a?(Property)
          active_properties = properties
        end
        active_properties = active_properties.select{|p| p.active?}

        active_properties.each do |property|
          if debug
            msg = "*** Fetching and processing Residents for #{property.name}"
            puts "\n\n" + msg
            Rails.logger.warn msg
          end
          service = Residents::Adapters::YardiVoyager.new(property)
          response = service.processResidents

          if debug
            response_msg = <<~EOS
            == #{response[:status].to_s.upcase} == #{response[:errors].join("\n")}
              - Processed #{response[:collection].size} Resident records
              - Updated #{response[:stats][:updated]} Resident records
              - Created #{response[:stats][:updated]} Resident records
            EOS

            puts response_msg
          end
        end
        true
      end

      def self.resident_from_voyager_resident(remote_resident, property)
        resident = ::Resident.where(residentid: remote_resident.residentid).first || Resident.new
        resident.detail ||= ResidentDetail.new
        new_record = resident.id.present?
        unit = property.housing_units.where(unit: remote_resident.unit_name).first
        resident.property_id ||= property.id
        resident.unit_id = unit.id if unit
        resident.residentid ||= remote_resident.residentid
        resident.status = remote_resident.status
        resident.first_name = remote_resident.first_name
        resident.middle_name = remote_resident.middle_name
        resident.last_name = remote_resident.last_name
        resident.address1 = remote_resident.address1
        resident.address2 = remote_resident.address2
        resident.city = remote_resident.city
        resident.state = remote_resident.state
        resident.zip = remote_resident.zip
        resident.country = remote_resident.country
        resident.detail.phone1 = remote_resident.phone1
        resident.detail.phone1_type = remote_resident.phone1_type
        resident.detail.phone2 = remote_resident.phone2
        resident.detail.phone2_type = remote_resident.phone2_type
        resident.detail.email = remote_resident.email
        resident
      end

      def initialize(property)
        @property = property
        @property_code = property.voyager_property_code
      end

      def processResidents
        debug = ['true', 'yes', '1'].include? ENV.fetch('DEBUG','false').to_s.downcase
        stub = ['true', 'yes', '1'].include? ENV.fetch('STUB_RESIDENT_API','false').to_s.downcase

        service = Yardi::Voyager::Api::Residents.new
        service.debug = debug
        service.stub = stub
        remote_collection = service.getResidents(@property_code)

        # status can be: nil, :ok, :warn, :error
        status = nil
        residents = []
        stats = { created: 0, updated: 0, noop: 0 ,errors: 0}
        errors = []
        begin
          Resident.transaction do
            residents = remote_collection.map do |remote_resident|
              resident = Residents::Adapters::YardiVoyager.resident_from_voyager_resident(remote_resident, @property)
              new_record = resident.id.present?

              if resident.save
                if new_record 
                  stats[:created] += 1
                elsif resident.previous_changes.any?
                  stats[:updated] += 1
                else
                  stats[:noop] += 1
                end
              else
                status ||= :warn
                msg = "#{@property.name} => #{new_record ? 'New ' : ''}Resident '#{remote_resident.first_name} #{remote_resident.last_name}' (#{remote_resident.residentid}) could not be saved: #{resident.errors.full_messages.join(';')}"
                errors << msg
                stats[:errors] += 1
              end
              resident
            end
          end
        rescue => e
          status = :error
          errors << e
        end

        {
          status: status || :ok,
          collection: residents,
          stats: stats,
          errors: errors || []
        }
      end

    end
  end
end
