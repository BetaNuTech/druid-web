module Properties
  module PhoneNumbers
    extend ActiveSupport::Concern

    included do
      has_many :phone_numbers, as: :phoneable, dependent: :destroy
      accepts_nested_attributes_for :phone_numbers, allow_destroy: true, reject_if: proc{|attributes| attributes['number'].blank? }

      def number_variants
        return (PhoneNumber.number_variants(phone) + phone_numbers.map(&:number_variants)).
          flatten.compact.sort.uniq
      end

    end
  end
end
