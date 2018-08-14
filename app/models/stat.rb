class Stat
  attr_reader :user_ids, :property_ids

  def initialize(user:, filters: {})
    @user_ids = get_user_ids(filters.fetch(:user_ids, []))
    @property_ids = get_property_ids(filters.fetch(:property_ids, []))
  end

  def lead_states
    skope = apply_skope(Lead)
    return skope.group(:state).count
  end

  def lead_states_json
    _lead_states = lead_states
    state_order = Lead.aasm.states.map(&:name).map(&:to_s)
    return state_order.map do |state_name|
      {label: state_name.humanize, val: ( _lead_states[state_name] || 0 ) }
    end
  end

  def lead_sources
    skope = apply_skope(Lead)
    skope.group(:lead_source_id).count
    return skope.joins("inner join lead_sources on leads.lead_source_id = lead_sources.id").group("concat(lead_sources.name, ' ' , leads.referral)").count
  end

  def lead_sources_conversion_json
    filters = []
    if @user_ids.present?
      filters << "leads.user_id in (#{@user_ids.map{|i| "'#{i}'"}.join(',')})"
    end
    if @property_ids.present?
      filters << "leads.property_id in (#{@property_ids.map{|i| "'#{i}'"}.join(',')})"
    end
    filter_sql = filters.map{|f| "(#{f})"}.join(" AND ")

    sql=<<-EOS
      SELECT
        total_counts.source_name as source_name,
        total_counts.total_count AS total_count,
        converted_counts.converted_count AS converted_count
      FROM (
        SELECT
          concat(lead_sources.name, ' ', leads.referral) AS source_name,
          count(*) AS total_count
        FROM leads
          JOIN lead_sources ON leads.lead_source_id = lead_sources.id
          #{ "WHERE #{filter_sql}" if filters.any?}
        GROUP BY ( lead_sources.name, leads.referral )
      ) total_counts
      RIGHT JOIN (
        SELECT
          concat(lead_sources.name, ' ', leads.referral) AS source_name,
          count(*) AS converted_count
        FROM leads
          JOIN lead_sources ON leads.lead_source_id = lead_sources.id
        WHERE (leads.state = 'movein')#{ " AND #{filter_sql}" if filters.any?}
        GROUP BY ( lead_sources.name, leads.referral )
      ) converted_counts
       ON total_counts.source_name = converted_counts.source_name;
EOS

    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      {
        label: record["source_name"].strip,
        val: {
                Total: record["total_count"],
                Converted: record["converted_count"]
             }
      }
    end

    return result
  end

  def lead_sources_json
    return lead_sources.map{|key, value| {label: key, val: value}}
  end

  private

  def apply_skope(skope)
    if @user_ids.present?
      skope = skope.where(user_id: @user_ids)
    end
    if @property_ids.present?
      skope = skope.where(property_id: @property_ids)
    end
    return skope
  end

  def get_user_ids(users)
    Array(users).map{|u| u.is_a?(User) ? u.id : u }
  end

  def get_property_ids(properties)
    Array(properties).map{|p| p.is_a?(Property) ? p.id : p }
  end

end
