module Properties
  module WorkingHours
    extend ActiveSupport::Concern
    require 'working_hours'

    included do

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
        ::WorkingHours::Config.with_config(working_hours_config) do
          Time.now.in_working_hours?
        end
      end

    end
  end
end
