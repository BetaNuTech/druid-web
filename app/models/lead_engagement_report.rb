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
    return '' unless data.present?

    CSV.generate do |csv|
      csv << data.first.keys
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

    @report = lead_scope.includes(:property, :user).all.inject([]) do |memo, lead|
      contacts = lead.contact_events.where(article_type: %w{Message LeadAction})
      total_contacts = contacts.count
      messages_sent = contacts.where(article_type: %w{Message}).count
      memo << {
        agent_name: lead.user.name,
        property_name: lead.property.name,
        lead_name: lead.name,
        lead_state: lead.state,
        first_contact: lead.first_comm,
        last_contact: lead.last_comm,
        messages_sent: messages_sent,
        total_contacts: total_contacts,
        lead_speed: lead.lead_speed,
        tenacity: ( lead.tenacity.round(1) rescue 0.0 )
      }

      memo
    end
  end

end
