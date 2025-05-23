class LeadEngagementReport
  DEFAULT_START_DATE_OFFSET = 1.month.freeze # seconds ago
  DEFAULT_END_DATE_OFFSET = 0.freeze # seconds ago

  attr_reader :options

  # Initialize with options
  # Example: { property_ids: [1,2,3], start_date: Time, end_date: Time }
  def initialize(options: {})
    @options = options
    @start_date = nil
    @end_date = nil
    @properties = nil
    @report = nil
  end

  def generate_csv
    data = report(true)
    return 'No data' unless data.present?

    CSV.generate do |csv|
      header = data.first.keys.map{|k| k.to_s.humanize.titlecase }
      csv << header
      data.each do |row|
        csv << row.values
      end
    end
  end

  def properties
    @properties ||= Property.find(
      @options.fetch(:properties, Property.active.pluck(:id)).
        map{|p| p.is_a?(Property) ? p.id : p}
    )
  end

  def start_date
    @start_date ||= begin
      default = ( Time.current - DEFAULT_START_DATE_OFFSET ).beginning_of_day
      @options.fetch(:start_date, default)
    end
  end

  def end_date
    @end_date ||= begin
      default = Time.current
      @options.fetch(:end_date, default)
    end
  end

  def lead_scope
    Lead.where(property: properties, classification: :lead, created_at: start_date..end_date).where.not(user_id: nil)
  end

  private

  def report(force=false)
    return @report if @report.present? && !force

    base_url = "%{protocol}://%{host}/leads/" % { 
      protocol: ENV.fetch('APPLICATION_PROTOCOL', 'https'),
      host: ENV.fetch('APPLICATION_HOST','www.blue-sky.app')
    }

    @report = lead_scope.includes(:property, :user).all.
        sort_by{|lead| [lead.property.name, lead.user.last_name, lead.user.first_name, lead.last_name, lead.first_name]}.
        inject([]) do |memo, lead|
      contacts = lead.contact_events.where(article_type: %w{Message LeadAction})
      total_contacts = contacts.count
      messages_sent = contacts.where(article_type: %w{Message}).count
      converted_to_resident = lead.conversion_date.present? || lead.state == 'resident' || lead.resident.present? 
      showing_completed = lead.showings.any? || lead.state == 'showing'
      memo << {
        property_name: lead.property.name,
        agent_name: lead.user.name,
        referral: lead.referral,
        lead_state: lead.state,
        lead_name: lead.name,
        first_contact: lead.first_comm,
        last_contact: lead.last_comm,
        agent_response_time: lead.contact_events.first_contact.first&.lead_time,
        messages_sent: messages_sent,
        total_contacts: total_contacts,
        lead_speed: lead.lead_speed,
        tenacity: ( lead.tenacity.round(1) rescue 0.0 ),
        conversion: ( showing_completed || converted_to_resident),
        showing: showing_completed,
        lease: converted_to_resident,
        lead_url: base_url + lead.id
      }

      memo
    end
  end

end
