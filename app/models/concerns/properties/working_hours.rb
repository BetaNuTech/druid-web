module Properties
  module WorkingHours
    extend ActiveSupport::Concern
    require 'working_hours/module'

    included do
      include WorkingHours
      DEFAULT_WORKING_HOURS = {
        'sunday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '11:30AM'},
          'afternoon' => {'open' => '6:00 AM', 'close' => '11:30AM'},
        },
        'monday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '11:30AM'},
          'afternoon' => {'open' => '6:00 AM', 'close' => '11:30AM'},
        },
        'tuesday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '11:30AM'},
          'afternoon' => {'open' => '6:00 AM', 'close' => '11:30AM'},
        },
        'wednesday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '11:30AM'},
          'afternoon' => {'open' => '6:00 AM', 'close' => '11:30AM'},
        },
        'thursday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '11:30AM'},
          'afternoon' => {'open' => '6:00 AM', 'close' => '11:30AM'},
        },
        'friday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '11:30AM'},
          'afternoon' => {'open' => '6:00 AM', 'close' => '11:30AM'},
        },
        'saturday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '11:30AM'},
          'afternoon' => {'open' => '6:00 AM', 'close' => '11:30AM'},
        }
      }

      def office_hours_today
        info = self.working_hours[Date.today.strftime("%A").downcase]
        if info['morning']['close'] == info['afternoon']['open']
          "%s to %s" % [
            info['morning']['open'],
            info['afternoon']['close'],
          ]
        else
          "%s to %s and %s to %s" % [
            info['morning']['open'],
            info['morning']['close'],
            info['afternoon']['open'],
            info['afternoon']['close'],
          ]
        end
      end

      def working_hours_config
        convert_datestr = ->(t) { Time.strptime(t,"%I:%M %P").strftime("%H:%M") }
        working_hours = self.working_hours.keys.inject({}) do |memo, obj|
          info = self.working_hours[obj]
          open_morning = convert_datestr.call(info['morning']['open'])
          close_morning = convert_datestr.call(info['morning']['close'])
          open_afternoon = convert_datestr.call(info['afternoon']['open'])
          close_afternoon = convert_datestr.call(info['afternoon']['close'])
          if close_morning == open_afternoon
            memo[obj.to_s.downcase[0..2].to_sym] = {
              open_morning => close_afternoon
            }
          else
            memo[obj.to_s.downcase[0..2].to_sym] = {
              open_morning => close_morning,
              open_afternoon => close_afternoon
            }
          end
          memo
        end

        {
          working_hours: working_hours,
          holidays: [],
          time_zone: 'America/Los_Angeles' # TODO use Property time zone
        }
      end

      def office_open?
        with_working_hours do
          Time.now.in_working_hours?
        end
      end

      def working_hours_difference_in_time(from, to)
        with_working_hours do
          (::WorkingHours.working_time_between(from, to) / 60).to_i
        end
      end

      def with_working_hours(&block)
        ::WorkingHours::Config.with_config(working_hours_config) do
          yield
        end
      end

      def closed_on_day_of_week?(dow)
        day_hours = working_hours[dow.to_s]
        [day_hours["morning"]["open"], day_hours["morning"]["close"], day_hours["afternoon"]["open"], day_hours["afternoon"]["close"]].
          all? { |h| h == "12:00 PM" }
      end

    end
  end
end
