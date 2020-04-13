# == Schema Information
#
# Table name: phone_numbers
#
#  id             :uuid             not null, primary key
#  name           :string
#  number         :string
#  prefix         :string           default("1")
#  category       :integer          default("0")
#  availability   :integer          default("0")
#  phoneable_id   :uuid
#  phoneable_type :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class PhoneNumber < ApplicationRecord
  ### Class Concerns/Extensions

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :number, :prefix, :category, :availability, :_destroy]

  ### Enums
  enum category: {cell: 0, home: 1, work: 2, fax: 3}
  enum availability: {any: 0, morning: 1, afternoon: 2, evening: 3}

  ### Attributes
  #

  ### Associations
  belongs_to :phoneable, polymorphic: true, optional: true

  ### Scopes
  #

  ### Validations
  validates :number, presence: true
  validates :name,
    presence: true,
    uniqueness: {scope: [:phoneable_id, :phoneable_type]}

  ### Callbacks
  before_validation :format_number

  ### Class Methods
  #
  def self.format_phone(number,prefixed: false)
    # Strip non-digits
    out = ( number || '' ).to_s.gsub(/[^0-9]/,'')

    if out.length > 10
      # Remove US country code
      if (out[0] == '1')
        out = out[1..-1]
      end
    end

    # Truncate number to 10 digits
    out = out[0..9]

    # Add country code if we want to prefix
    if prefixed
      out = "1" + out
    end

    return out
  end

  def self.number_variants(numbers)
    numbers = Array(numbers).compact.select{|number| (number || '').length > 1}
    return numbers.
      map{|number| [ self.format_phone(number), self.format_phone(number, prefixed: true) ]}.
      flatten.uniq.select{|n| n.length >= 10}
  end

  ### Instance Methods

  def format_number
    if number.present?
      if detected_prefix = number.match(/^\+(\d)/)
        self.prefix = detected_prefix[1]
        self.number = self.class.format_phone(number, prefixed: false)
      else
        self.number = self.class.format_phone(number)
      end
    end
    return self.number
  end

  def number_variants
    self.class.number_variants(number)
  end
end
