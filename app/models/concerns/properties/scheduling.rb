module Properties
  module Scheduling
    extend ActiveSupport::Concern

    DEFAULT_TIMEZONE =  'Central Time (US & Canada)'

    class_methods do
      def schedule_availability(property, params)
        property_listing_code = params[:property_code]
        start_time = params[:start_time]
        end_time = params[:end_time]
        timezone = property.timezone || DEFAULT_TIMEZONE
        service = Properties::Scheduler.new(property)
        availability = nil
        Time.use_zone(property.timezone) do
          abbr_timezone = Time.zone.tzinfo.abbr
          availability = service.availability(
              start_time: start_time,
              end_time: end_time,
            ).
            group_by{|opening| opening.first.to_date}.to_a.
            inject([]) do |memo, obj|
              if obj.present?
                record = {
                  date: obj.first.strftime('%m/%d/%Y'),
                  day: Date::DAYNAMES[obj.first.wday],
                  times: obj.last.map{|opening| opening.first.strftime("%H:%M") + abbr_timezone }
                }
                memo << record
              end
              memo
            end
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
