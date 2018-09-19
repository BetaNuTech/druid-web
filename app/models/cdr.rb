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
  scope :calls_for, -> (numbers) {
    variants = self.number_variants(numbers)
    where("src IN (:src) OR dst IN (:dst)",
           { dst: variants, src: variants}).
      order("calldate DESC")
  }

  ### Class Methods

  def self.for_leads(start_date:, end_date:, recordings: true)
    variants = number_variants(Lead.select(:phone1, :phone2).all.map{|l| [l.phone1, l.phone2]}.flatten.compact.uniq)
    skope = select(:id, :calldate, :src, :dst, :recordingfile).
      where("calldate >= :start_date AND calldate <= :end_date", { start_date: start_date, end_date: end_date }).
      where("src IN (:src) AND dst IN (:dst)", { dst: variants, src: variants})
    if recordings
      skope = skope.where("recordingfile IS NOT null AND recordingfile != ''")
    end
    return skope
  end

  def self.lead_recordings(start_date:, end_date:)
    self.for_leads(start_date: start_date, end_date: end_date).
      map{|cdr| cdr.recording_path_key}.
      sort
  end

  def self.non_leads(start_date:, end_date:, recordings: true)
    variants = number_variants(Lead.select(:phone1, :phone2).all.map{|l| [l.phone1, l.phone2]}.flatten.compact.uniq)
    skope = select(:id, :calldate, :src, :dst, :recordingfile).
      where("calldate >= :start_date AND calldate <= :end_date", { start_date: start_date, end_date: end_date }).
      where("src NOT IN (:src) AND dst NOT IN (:dst)", { dst: variants, src: variants})
    if recordings
      skope = skope.where("recordingfile IS NOT null AND recordingfile != ''")
    end
    return skope
  end

  def self.possible_leads(start_date:, end_date:)
    variants = number_variants(Lead.select(:phone1, :phone2).all.
                                 map{|l| [l.phone1, l.phone2]}.flatten.compact.uniq) +
                ["Anonymous", "Restricted"]
    skope = select(:id, :calldate, :did, :src, :dst, :dcontext, :clid, :cnam).
      where("did != ''").
      where("src NOT IN (:src) AND dst NOT IN (:dst)", { dst: variants, src: variants}).
      where("calldate >= :start_date AND calldate <= :end_date", { start_date: start_date, end_date: end_date }).
      group(:cnam)
  end

  def self.non_lead_recordings(start_date:, end_date:)
    self.non_leads(start_date: start_date, end_date: end_date).
      map{|cdr| cdr.recording_path_key}.
      sort
  end

  def self.cleanup_non_lead_recordings(start_date:, end_date:)
    Rails.logger.warn("CDR Recording Cleanup: Identifying Non-Lead Call recordings")
    keys = self.non_lead_recordings(start_date: start_date, end_date: end_date)
    Rails.logger.warn("CDR Recording Cleanup: Found #{keys.count} keys to delete")

    # AWS only allows us to delete 1000 objects at a time
    keys.each_slice(1000).each do |key_set|
      Rails.logger.warn("CDR Recording Cleanup: Deleting #{keys.count} objects")
      response = ::CDRDB_CALL_RECORDING_S3_CLIENT.delete_objects({
        bucket: ::CDRDB_CALL_RECORDING_S3_CONFIG[:bucket],
        delete: {
          objects: key_set.map{|k| {key: k}},
          quiet: false
        }
      })
      Rails.logger.warn("CDR Recording Cleanup: Deleted objects: #{response.to_h.inspect}")
    end
  end

  def self.format_phone(number,prefixed: false)
    # Strip non-digits
    out = ( number || '' ).to_s.gsub(/[^0-9]/,'')

    if out.length > 10
      # Remove country code
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

  # CDR records are read-only
  def readonly?
    true
  end


  private

end
