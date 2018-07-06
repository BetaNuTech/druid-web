# == Schema Information
#
# Table name: cdr
#
#  id            :integer          unsigned, not null, primary key
#  calldate      :datetime         default(NULL), not null
#  clid          :string(80)       default(""), not null
#  src           :string(80)       default(""), not null
#  dst           :string(80)       default(""), not null
#  dcontext      :string(80)       default(""), not null
#  channel       :string(80)       default(""), not null
#  dstchannel    :string(80)       default(""), not null
#  lastapp       :string(80)       default(""), not null
#  lastdata      :string(80)       default(""), not null
#  duration      :integer          default(0), not null
#  billsec       :integer          default(0), not null
#  disposition   :string(45)       default(""), not null
#  amaflags      :integer          default(0), not null
#  accountcode   :string(20)       default(""), not null
#  uniqueid      :string(32)       default(""), not null
#  userfield     :string(255)      default(""), not null
#  did           :string(50)       default(""), not null
#  recordingfile :string(255)      default(""), not null
#  cnum          :string(40)       default(""), not null
#  cnam          :string(40)       default(""), not null
#  outbound_cnum :string(40)       default(""), not null
#  outbound_cnam :string(40)       default(""), not null
#  dst_cnam      :string(40)       default(""), not null
#  flag_imported :integer          default(0)
#

### Data Reference: https://wiki.asterisk.org/wiki/display/AST/Asterisk+12+CDR+Specification

# Asterisk Call Data Records
class Cdr < CdrdbModel
  ### Class Concerns/Extensions/Configuration
  self.table_name = 'cdr'
  include Cdrs::Aws

  ### Constants
  #DCONTEXTS = ["app-blackhole", "app-blacklist-add", "app-blacklist-remove", "app-calltrace-perform", "default", "ext-fax", "ext-group", "ext-local", "ext-meetme", "ext-queues", "from-did-direct", "from-internal", "from-internal-xfer", "from-queue", "from-trunk", "from-trunk-sip-a2b", "from-trunk-sip-voxox", "ivr-1", "ivr-10", "ivr-11", "ivr-12", "ivr-13", "ivr-14", "ivr-15", "ivr-16", "ivr-17", "ivr-18", "ivr-19", "ivr-20", "ivr-21", "ivr-22", "ivr-23", "ivr-24", "ivr-25", "ivr-26", "ivr-27", "ivr-28", "ivr-29", "ivr-30", "ivr-31", "ivr-32", "ivr-33", "ivr-34", "ivr-35", "ivr-36", "ivr-37", "ivr-39", "ivr-4", "ivr-40", "ivr-5", "ivr-6", "ivr-7", "ivr-8", "ivr-9", "vm-callme"]

  ### Scopes

  ### Class Methods

  def self.calls_for(numbers)
    variants = self.number_variants(numbers)
    self.select(:id, :calldate, :src, :dst, :dcontext, :disposition, :recordingfile).
      where("src IN (:src) OR dst IN (:dst)",
             { dst: variants, src: variants}).
      order("calldate DESC")
  end

  def self.format_phone(number,prefixed: false)
    # Strip non-digits
    out = ( number || '' ).to_s.gsub(/[^0-9]/,'')

    # Remove country code
    if (out[0] == '1')
      out = out[1..-1]
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

  # CDR records are read-only
  def readonly?
    true
  end


  private

end
