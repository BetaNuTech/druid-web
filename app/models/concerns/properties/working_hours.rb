module Properties
  module WorkingHours
    extend ActiveSupport::Concern
    require 'working_hours/module'

    class WorkingHoursValidator < ActiveModel::Validator
      def validate(record)
        return true if record.working_hours.nil? || record.working_hours.empty?

        unless record.working_hours_valid?
          record.errors.add :working_hours, record.working_hours_error
        end
      end
    end

    included do
      include WorkingHours
      DEFAULT_WORKING_HOURS = {
        'sunday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
          'afternoon' => {'open' => '12:00PM', 'close' => '5:00PM'},
        },
        'monday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
          'afternoon' => {'open' => '12:00PM', 'close' => '5:00PM'},
        },
        'tuesday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
          'afternoon' => {'open' => '12:00PM', 'close' => '5:00PM'},
        },
        'wednesday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
          'afternoon' => {'open' => '12:00PM', 'close' => '5:00PM'},
        },
        'thursday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
          'afternoon' => {'open' => '12:00PM', 'close' => '5:00PM'},
        },
        'friday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
          'afternoon' => {'open' => '12:00PM', 'close' => '5:00PM'},
        },
        'saturday' => {
          'morning' => {'open' => '6:00 AM', 'close' => '12:00PM'},
          'afternoon' => {'open' => '12:00PM', 'close' => '5:00PM'},
        }
      }

      validates_with WorkingHoursValidator

      def office_holidays
        office_observed_names = ["New Year's Day", "Memorial Day", "Independence Day", "Labor Day", "Thanksgiving", "Christmas Day"]
        all_federal = Holidays.between(Date.today.beginning_of_year, Date.today.end_of_year - 1.day, :us)
        all_federal_observed = Holidays.between(Date.today.beginning_of_year, Date.today.end_of_year - 1.day, :us, :observed)
        office_observed = all_federal_observed.select{|d| office_observed_names.include?(d[:name])}.map{|d| d[:date]}
        office_observed += all_federal.select{|d| office_observed_names.include?(d[:name])}.map{|d| d[:date]}
        office_observed << all_federal.select{|d| d[:name] == "Thanksgiving"}.first[:date] + 1.day # Day after thanksgiving
        office_observed << all_federal.select{|d| d[:name] == "Christmas Day"}.first[:date] - 1.day # Christmas Eve
        office_observed << Date.new(Date.today.year,12,31)
        office_observed.sort.uniq
      end

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
        convert_datestr = ->(t) { 
          if t.present?
            Time.strptime(t,"%I:%M %P").strftime("%H:%M")
          else
            nil
          end
        }
        working_hours = ( self.working_hours || {} ).keys.inject({}) do |memo, obj|
          info = self.working_hours[obj]
          open_morning = convert_datestr.call(info['morning']['open'])
          close_morning = convert_datestr.call(info['morning']['close'])
          open_afternoon = convert_datestr.call(info['afternoon']['open'])
          close_afternoon = convert_datestr.call(info['afternoon']['close'])
          if [open_morning, close_morning, open_afternoon, close_afternoon].all?(&:nil?)
            # Data is missing by design or accident, so we will treat the day as closed
            # NOOP: omit day from Hash which means closed all day
          elsif close_morning == open_afternoon
            memo[obj.to_s.downcase[0..2].to_sym] = {
              open_morning => close_afternoon
            }
          elsif open_morning.blank? && close_morning.blank?
            memo[obj.to_s.downcase[0..2].to_sym] = {
              open_afternoon => close_afternoon
            }
          elsif open_afternoon.blank? && close_afternoon.blank?
            memo[obj.to_s.downcase[0..2].to_sym] = {
              open_morning => close_morning,
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
          holidays: office_holidays,
          time_zone: timezone
        }
      end

      def office_open?(datetime=nil)
        with_working_hours do
          (datetime || Time.now).in_working_hours?
        end
      rescue
        true
      end

      def working_hours_difference_in_time(from, to)
        with_working_hours do
          (::WorkingHours.working_time_between(from, to) / 60).to_i
        end
      end

      def with_working_hours(&block)
        ::WorkingHours::Config.with_config(**working_hours_config) do
          yield
        end
      end

      def working_hours_valid?
        ::WorkingHours::Config.with_config(**working_hours_config) do
          true
        end
      rescue => e
        false
      end

      def working_hours_error
        ::WorkingHours::Config.with_config(**working_hours_config) do
          nil
        end
      rescue => e
        e.to_s
      end

      def working_hours_or_defaults
        effective_hours = working_hours.nil? || working_hours.empty? ? DEFAULT_WORKING_HOURS : working_hours
        DEFAULT_WORKING_HOURS.keys.each do |day|
          effective_day_hours = effective_hours[day] ||
            {
              'morning' => { 'open' => nil, 'close' => nil},
              'afternoon' => { 'open' => nil, 'close' => nil},
            }
          effective_hours[day] = effective_day_hours
        end
        OpenStruct.new effective_hours
        #OpenStruct.new working_hours.nil? || working_hours.empty? ? DEFAULT_WORKING_HOURS : working_hours
      end

      def closed_on_day_of_week?(dow)
        return false if working_hours.nil? || working_hours.empty?
        day_hours = working_hours[dow.to_s]

        return true if day_hours.nil? || day_hours.empty?

        [day_hours["morning"]["open"], day_hours["morning"]["close"], day_hours["afternoon"]["open"], day_hours["afternoon"]["close"]].
          all? { |h| h.nil? || h.empty? }
      end

      def closed_on_mornings?(dow)
        return false if working_hours.nil? || working_hours.empty?
        day_hours = working_hours[dow.to_s]

        return true if day_hours.nil? || day_hours.empty?

        [day_hours["morning"]["open"], day_hours["morning"]["close"]].
          all? { |h| h.nil? || h.empty? }
      end

      def closed_on_afternoons?(dow)
        return false if working_hours.nil? || working_hours.empty?
        day_hours = working_hours[dow.to_s]

        return true if day_hours.nil? || day_hours.empty?

        [day_hours["afternoon"]["open"], day_hours["afternoon"]["close"]].
          all? { |h| h.nil? || h.empty? }
      end


    end
  end
end
