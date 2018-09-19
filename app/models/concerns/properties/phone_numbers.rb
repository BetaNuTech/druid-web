module Properties
  module PhoneNumbers
    extend ActiveSupport::Concern

    included do
      has_many :phone_numbers, -> { order(name: :asc) }, as: :phoneable, dependent: :destroy
      accepts_nested_attributes_for :phone_numbers, allow_destroy: true, reject_if: proc{|attributes| attributes['number'].blank? }

      def number_variants
        return (PhoneNumber.number_variants(phone) + phone_numbers.map(&:number_variants)).
          flatten.compact.sort.uniq
      end

      def all_numbers
        return ([phone] + phone_numbers.map(&:number)).flatten.compact.uniq.select{|n| n.present?}
      end

    end

    class_methods do

      def find_by_phone_number(number)
        return nil unless number.present?
        self.includes(:phone_numbers).
          where(phone: PhoneNumber.format_phone(number)).
          or(includes(:phone_numbers).where(phone_numbers: {number: PhoneNumber.format_phone(number)})).
          first
      end

      def find_all_by_phone_numbers(numbers)
        sanitized_numbers = (numbers ||[]).select{|n| n.present?}
        formatted_numbers = sanitized_numbers.map{|n| PhoneNumber.format_phone(n)}
        self.includes(:phone_numbers).
          where(phone: formatted_numbers).
          or(includes(:phone_numbers).where(phone_numbers: {number: formatted_numbers}))
      end

    end
  end
end
