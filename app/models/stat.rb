class Stat
  attr_reader :user_ids, :property_ids, :users, :properties
  include ActionView::Helpers::DateHelper

  def initialize(user:, filters: {})
    @user_ids = get_user_ids(filters.fetch(:user_ids, []))
    @property_ids = get_property_ids(filters.fetch(:property_ids, []))
    @users = User.find(@user_ids)
    @properties = Property.find(@property_ids)
  end

  def filters_json
    agent_properties = @properties.any? ? @properties.map(&:id) : Property.order("name ASC")
    {
      options: {
        _index: ['users', 'properties'],
        users: {
          label: 'Agents',
          param: 'user_ids',
          options: 
            PropertyAgent.where(property_id: agent_properties).
              map(&:user).
              map{|u| { label: u.name, val: u.id}}
        },
        properties: {
          label: 'Properties',
          param: 'property_ids',
          options: Property.where("id NOT IN (?)", @property_ids).order('name ASC').map{|p|
            {label: p.name, val: p.id}
          }
        },
      },
      users: @users.map{|user| {label: user.name, val: user.id}},
      properties: @properties.map{|property| {label: property.name, val: property.id}}
    }
  end

  def lead_states
    skope = apply_skope(Lead)
    return skope.group(:state).count
  end

  def lead_states_json
    _lead_states = lead_states
    state_order = Lead.aasm.states.map(&:name).map(&:to_s)
    return state_order.map do |state_name|
      {label: state_name.humanize, val: ( _lead_states[state_name] || 0 ), id: state_name}
    end
  end

  def lead_sources
    skope = apply_skope(Lead)
    skope.group(:lead_source_id).count
    return skope.joins("inner join lead_sources on leads.lead_source_id = lead_sources.id").group("concat(lead_sources.name, ' ' , leads.referral)").count
  end

  def lead_sources_conversion_json
    _filter_sql = filter_sql
    converted_states = %w{movein resident exresident}
    converted_states_sql = "leads.state IN (%s)" % converted_states.map{|s| "'#{s}'"}.join(',')

    sql=<<-EOS
      SELECT
        total_counts.source_id as source_id,
        total_counts.source_name as source_name,
        total_counts.total_count AS total_count,
        converted_counts.converted_count AS converted_count
      FROM (
        SELECT
          lead_sources.id AS source_id,
          concat(lead_sources.name, ' ', leads.referral) AS source_name,
          count(*) AS total_count
        FROM leads
          JOIN lead_sources ON leads.lead_source_id = lead_sources.id
        #{ "WHERE #{_filter_sql}" if _filter_sql.present?}
        GROUP BY ( lead_sources.name, lead_sources.id, leads.referral )
      ) total_counts
      FULL OUTER JOIN (
        SELECT
          concat(lead_sources.name, ' ', leads.referral) AS source_name,
          count(*) AS converted_count
        FROM leads
          JOIN lead_sources ON leads.lead_source_id = lead_sources.id
        WHERE (#{converted_states_sql})#{ " AND #{_filter_sql}" if _filter_sql.present?}
        GROUP BY ( lead_sources.name, leads.referral )
      ) converted_counts
       ON total_counts.source_name = converted_counts.source_name;
EOS

    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      {
        label: record["source_name"].strip,
        val: {
                Total: record["total_count"] || 0,
                Converted: record["converted_count"] || 0
             },
        id: record["source_id"]
      }
    end

    return result
  end

  def lead_sources_json
    return lead_sources.map{|key, value| {label: key, val: value}}
  end

  def property_leads_json
    _filter_sql = filter_sql

    sql=<<-EOS
      SELECT
        properties.id AS property_id,
        properties.name AS property_name,
        count(*) AS total_count
      FROM leads
      INNER JOIN properties
        ON leads.property_id = properties.id
      #{ "WHERE #{_filter_sql}" if _filter_sql.present?}
      GROUP BY properties.name, properties.id
      ORDER BY properties.name
EOS

    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      {
        label: record["property_name"],
        val: record["total_count"],
        id: record["property_id"]
      }
    end
  end

  def open_leads
    skope = apply_skope(Lead)
    skope.
      where(state: 'open').
      order(created_at: "asc")
  end

  def open_leads_json
    {
      total: open_leads.count,
      count: open_leads.limit(10).count,
      series: open_leads.limit(10).map do |lead|
          {
            id: lead.id,
            label: lead.name,
            created_at: distance_of_time_in_words(lead.created_at, DateTime.now),
            url: "/leads/#{lead.id}",
            priority: lead.priority,
            property_id: lead.property_id,
            source: "#{lead.source.name}#{lead.referral.present? ? " " + lead.referral : ''}"
          }
        end
    }
  end

  def agent_status_json
    skope = User.includes(:properties)
    if @user_ids.present?
      skope = skope.where(id: @user_ids)
    end
    if @property_ids.present?
      skope = skope.where(property_agents: {property_id: @property_ids})
    end

    return {
        series: skope.map do |user|
          {
            id: user.id,
            label: user.name,
            total_score: user.score,
            weekly_score: user.weekly_score,
            tasks_completed: user.tasks_completed.count,
            tasks_pending: user.tasks_pending.count,
            claimed_leads: user.claimed_leads.count,
            closed_leads: user.closed_leads.count,
            url: "/users/#{user.id}"
          }
        end
      }
  end

  private

  def filter_sql
    filters = []
    if @user_ids.present?
      filters << "leads.user_id in (#{@user_ids.map{|i| "'#{i}'"}.join(',')})"
    end
    if @property_ids.present?
      filters << "leads.property_id in (#{@property_ids.map{|i| "'#{i}'"}.join(',')})"
    end
    return filters.map{|f| "(#{f})"}.join(" AND ")
  end

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
