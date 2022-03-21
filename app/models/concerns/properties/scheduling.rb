module Properties
  module Scheduling
    extend ActiveSupport::Concern

    class_methods do
      def schedule_availability(property, params)
        property_listing_code = params[:property_code]
        start_time = params[:start_time]
        end_time = params[:end_time]
        service = Properties::Scheduler.new(property)

        # TODO timezone handling
        availability = service.availability(
            start_time: start_time,
            end_time: end_time,
          ).
          group_by{|opening| opening.to_date}.
          inject([]) do |obj, memo|
            record = {
              date: obj.first.strftime('%m/%d/%Y'),
              day: Date::DAYNAMES[obj.first.wday],
              times: obj.last.map{|opening| opening.first }
            }
            memo << record
            memo
          end

        {
          propertyId: property_listing_code,
          appointmentLength: service.appointment_length,
          category: 'onsite-tour',
          availability: availability
        }
      end
    end
  end
end
