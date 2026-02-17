class Stat
  attr_reader :user_ids, :property_ids, :team_ids, :users, :properties, :teams, :url, :start_date, :end_date, :date_range
  include ActionView::Helpers::DateHelper

  class ActivityEntry
    ATTRS = %w{ agent_id agent_name date description entry_type lead_id lead_name link raw_date }

    attr_accessor *(ATTRS.map(&:to_sym))

    def initialize(**args)
      args.each do |key, value|
        instance_variable_set("@#{key}", value) if ATTRS.include?(key.to_s)
      end
    end

    def to_h
      return ATTRS.inject({}){ |memo, obj| memo[obj] = instance_variable_get("@#{obj}"); memo }
    end
  end

  DATE_RANGES = {
    today: 'Today',
    last_week: 'Last Week',
    last_month: 'Last Month',
    last_quarter: 'Last Quarter',
    last_year: 'Last Year',
    all_time: 'All Time',
    week: '7 days until today',
    '2weeks': '14 days until today',
    month: '30 Days until today',
    '3months': '3 Months until today',
    year: '12 Months until today',
    custom: 'Custom Range'
  }


  def initialize(filters: {}, url: "/stats/manager")
    @url = url
    @filters = filters
    @user_ids = get_user_ids(@filters.fetch(:user_ids, []))
    @property_ids = get_property_ids(@filters.fetch(:property_ids, []))
    @team_ids = get_team_ids(@filters.fetch(:team_ids,[]))
    # Extract timezone from filters for timezone-aware date calculations
    @timezone = Array(@filters.fetch(:timezone, [])).compact.first
    @date_range, @start_date, @end_date = get_date_range(@filters)
    @users = User.find(@user_ids)
    @properties = Property.find(@property_ids)
    @teams = Team.find(@team_ids)
  end

  def json_url
    return url + "?filter=true&" + @filters.to_a.compact.inject([]){|memo, obj| memo << ( obj[1] || [] ).map{|f| "#{obj[0]}[]=#{f}" }.join('&') ; memo}.join('&')
  end

  def filters_json
    team_properties = @teams.present? ? Property.active.where(team_id: @team_ids).order("name ASC") : Property.active.order("name ASC")
    filter_properties = @properties.present? ? @properties : team_properties
    users = User.includes(:properties).where(properties: {id: filter_properties.map(&:id)}).sort_by(&:last_name)
    if @date_range.nil?
      _date_range = []
    else
      _date_range_label = DATE_RANGES.fetch(@date_range.to_sym)
      _date_range = [ {label: _date_range_label, val: @date_range} ]
    end

    return {
      options: {
        _index: ['users', 'properties', 'teams', 'date_range'],
        users: {
          label: 'Agents',
          param: 'user_ids',
          options: users.map{|u| { label: u.name, val: u.id}}
        },
        properties: {
          label: 'Properties',
          param: 'property_ids',
          options: team_properties.map{|p|
            {label: p.name, val: p.id}
          }
        },
        teams: {
          label: 'Teams',
          param: 'team_ids',
          options: Team.order("name ASC").map{|t|
            {label: t.name, val: t.id}
          }
        },
        date_range: {
          label: 'Date Range',
          param: 'date_range',
          options: DATE_RANGES.map{|k,v|
            {label: v, val: k}
          }
        }
      },
      users: @users.map{|user| {label: user.name, val: user.id}},
      properties: @properties.map{|property| {label: property.name, val: property.id}},
      teams: @teams.map{|team| {label: team.name, val: team.id}},
      date_range: _date_range
    }
  end

  #def daily_referral_stats_json
    #_filters = []
    #_lead_filter_sql = filter_sql
    #_filters << _lead_filter_sql if _lead_filter_sql.present?
    #if @start_date.nil?
      #_filters << "leads.first_comm BETWEEN '%s' AND '%s'" % [
        #7.days.ago.strftime("%Y-%m-%d"),
        #(Date.current + 1.day).strftime("%Y-%m-%d"),
      #]
    #end
    #sql=<<-EOS
      #SELECT properties.name, properties.id, leads.referral, date(leads.created_at) as lead_day, count(leads.id) as lead_count
      #FROM properties
      #INNER JOIN leads on leads.property_id = properties.id
      ##{" WHERE #{_filters.join(' AND ' )}" if _filters.any?}
      #GROUP BY
        #properties.id, leads.referral, lead_day
      #ORDER BY
        #lead_day DESC, properties.name ASC, leads.referral ASC
    #EOS
    #raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    #result = raw_result.inject({}) do |memo, obj|
      #memo[obj['lead_day']] ||= {}
      #memo[obj['lead_day']][obj['name']] ||= {}
      #memo[obj['lead_day']][obj['name']][obj['referral']] = obj['lead_count']
      #memo
    #end
    #return result
  #end

  def agent_conversion_rates_json
    _lead_filter_sql = filter_sql
    _lead_transition_filter_sql = lead_transition_filter_sql
    sql=<<-EOS
    SELECT
      total_counts.user_id AS agent_id,
      total_counts.user_name AS agent_name,
      total_counts.lead_count AS prospects,
      invalidated_counts.lead_count AS invalidated,
      conversion_counts.lead_count AS conversions,
      closing_counts.lead_count AS closes,
      floor(100.0 * conversion_counts.lead_count::float / total_counts.lead_count::float)::integer AS conversion_rate,
      floor(100.0 * closing_counts.lead_count::float / total_counts.lead_count::float) AS closing_rate
    FROM (
      SELECT
        users.id AS user_id,
        concat(user_profiles.first_name, ' ', user_profiles.last_name) AS user_name,
        count(leads.id) AS lead_count
      FROM leads
      INNER JOIN users
        ON leads.user_id = users.id
      INNER JOIN user_profiles
        ON user_profiles.user_id = users.id
      INNER JOIN lead_transitions
        ON lead_transitions.lead_id = leads.id
          AND lead_transitions.current_state = 'prospect'
      #{ "WHERE #{_lead_filter_sql}" if _lead_filter_sql.present?}
      GROUP BY users.id, user_name
    ) total_counts
    FULL OUTER JOIN (
      SELECT
        users.id AS user_id,
        concat(user_profiles.first_name, ' ', user_profiles.last_name) AS user_name,
        count(leads.id) AS lead_count
      FROM leads
      INNER JOIN users
        ON leads.user_id = users.id
      INNER JOIN user_profiles
        ON user_profiles.user_id = users.id
      INNER JOIN lead_transitions
        ON lead_transitions.lead_id = leads.id
          AND (lead_transitions.current_state = 'future' OR (lead_transitions.current_state = 'invalidated' AND leads.classification = 2))
      #{ "WHERE #{_lead_filter_sql}" if _lead_filter_sql.present?}
      GROUP BY users.id, user_name
    ) invalidated_counts
      ON total_counts.user_id = invalidated_counts.user_id
    FULL OUTER JOIN (
      SELECT
        users.id AS user_id,
        count(leads.id) AS lead_count
      FROM leads
      INNER JOIN users
        ON leads.user_id = users.id
      INNER JOIN lead_transitions
        ON lead_transitions.lead_id = leads.id
          AND (
                lead_transitions.current_state = 'showing'
                OR ( lead_transitions.current_state = 'application' AND lead_transitions.last_state = 'showing' )
              )
      #{ "WHERE #{_lead_transition_filter_sql}" if _lead_transition_filter_sql.present?}
      GROUP BY users.id
    ) conversion_counts
      ON total_counts.user_id = conversion_counts.user_id
    FULL OUTER JOIN (
      SELECT
        users.id AS user_id,
        count(leads.id) AS lead_count
      FROM leads
      INNER JOIN users
        ON leads.user_id = users.id
      INNER JOIN lead_transitions
        ON lead_transitions.lead_id = leads.id
          AND lead_transitions.current_state = 'application'
      #{ "WHERE #{_lead_transition_filter_sql}" if _lead_transition_filter_sql.present?}
      GROUP BY users.id
    ) closing_counts ON
      total_counts.user_id = closing_counts.user_id
    ORDER BY agent_name ASC
EOS

    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      {
        label: ( ( record["agent_name"] || '' ).empty? ? 'Unknown' : record["agent_name"] ).strip,
        val: {
                "Conversion Rate": record["conversion_rate"] || 0,
                "Closing Rate": record["closing_rate"] || 0
             },
        id: record["agent_id"]
      }
    end

    return result
  end

  def referral_conversion_rates_json
    _lead_filter_sql = filter_sql
    _lead_transition_filter_sql = lead_transition_filter_sql
    sql=<<-EOS
    SELECT
      ( total_counts.referral_name ) AS referral_name,
      total_counts.lead_count AS prospects,
      conversion_counts.lead_count AS conversions,
      closing_counts.lead_count AS closes,
      floor(100.0 * conversion_counts.lead_count::float / total_counts.lead_count::float)::integer AS conversion_rate,
      floor(100.0 * closing_counts.lead_count::float / total_counts.lead_count::float)::integer AS closing_rate
    FROM (
      SELECT
        leads.referral AS referral_name,
        count(leads.id) AS lead_count
      FROM leads
      INNER JOIN lead_transitions
        ON lead_transitions.lead_id = leads.id
          AND lead_transitions.current_state = 'prospect'
      #{ "WHERE #{_lead_filter_sql}" if _lead_filter_sql.present?}
      GROUP BY leads.referral
    ) total_counts
    FULL OUTER JOIN (
      SELECT
        leads.referral AS referral_name,
        count(leads.id) AS lead_count
      FROM leads
      INNER JOIN lead_transitions
        ON lead_transitions.lead_id = leads.id
          AND (
                lead_transitions.current_state = 'showing'
                OR ( lead_transitions.current_state = 'application' AND lead_transitions.last_state = 'showing' )
              )
      #{ "WHERE #{_lead_transition_filter_sql}" if _lead_transition_filter_sql.present?}
      GROUP BY referral_name
    ) conversion_counts
      ON total_counts.referral_name = conversion_counts.referral_name
    FULL OUTER JOIN (
      SELECT
        leads.referral AS referral_name,
        count(leads.id) AS lead_count
      FROM leads
      INNER JOIN lead_transitions
        ON lead_transitions.lead_id = leads.id
          AND lead_transitions.current_state = 'application'
      #{ "WHERE #{_lead_transition_filter_sql}" if _lead_transition_filter_sql.present?}
      GROUP BY leads.referral
    ) closing_counts ON
      total_counts.referral_name = closing_counts.referral_name
    ORDER BY referral_name ASC
EOS

    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      {
        label: ( ( record["referral_name"] || '' ).empty? ? 'Unknown' : record["referral_name"] ).strip,
        val: {
                "Conversion Rate": record["conversion_rate"] || 0,
                "Closing Rate": record["closing_rate"] || 0
             },
        id: record["referral_name"]
      }
    end

    return result
  end

  def statistics_collection
    collection = { team: [], property: [], agent: [] }

    if @team_ids.present?
      collection[:team] += Team.where(id: @team_ids).order(name: :asc).pluck(:id)
      collection[:property] += Property.active.includes(:team).where(team: {id: @team_ids}).pluck(:id)
      collection[:agent] += User.active.includes(:profile, :membership).where(team_users: {team_id: @team_ids}).pluck(:id)
    end

    if @user_ids.present?
      collection[:agent] += User.active.includes(:profile).where(id: @user_ids).pluck(:id)
      collection[:property] += Property.active.includes(:property_users).where(property_users: {user_id: @user_ids}).pluck(:id)
      collection[:team] += Team.includes(:members).where(team_users: {user_id: @user_ids}).pluck(:id)
    end

    if @property_ids.present?
      collection[:property] += Property.active.where(id: @property_ids).pluck(:id)
      collection[:agent] += User.active.includes(:profile, :assignments).where(property_users: {property_id: @property_ids}).pluck(:id)
      collection[:team] += Team.includes(:properties).where(properties: {id: @property_ids}).pluck(:id)
    end

    if !@team_ids.present? && !@user_ids.present? && !@property_ids.present?
      collection[:property] += Property.active.pluck(:id)
    end

    collection[:property] = Property.active.where(id: collection[:property].uniq).order(name: :asc)
    collection[:agent] = User.includes(:profile).active.where(id: collection[:agent].uniq).order("user_profiles.last_name ASC, user_profiles.first_name ASC")
    collection[:team] = Team.where(id: collection[:team].uniq).order(name: :asc)

    return collection
  end

  def tenacity_stats_json
    collection = statistics_collection
    interval = Statistic.interval_from_date_range(@date_range, :tenacity)
    time_start = Statistic.statistic_time_start(interval, :tenacity)
    stats = {}
    [:team, :property, :agent].each do |key|
      collection[key].each do |record|
        if key == :property && interval == :month
          value = Statistic.rolling_month_property_tenacity_grade(record)  
        else
          value = Statistic.tenacity_grade_for(record, interval: interval, time_start: time_start)
        end
        stats[key] ||= []
        stats[key] << {
          type: key,
          label: record.name,
          id: record.id,
          value: value
        }
      end
    end
    return stats
  end

  def lead_speed_stats_json
    collection = statistics_collection
    stats = {}
    interval = Statistic.interval_from_date_range(@date_range, :lead_speed)
    time_start = Statistic.statistic_time_start(interval, :lead_speed)
    [:team, :property, :agent].each do |key|
      collection[key].each do |record|
        if key == :property && (['month', 'last_month'].include?(interval.to_s))
          value = Statistic.rolling_month_property_leadspeed_grade(record)  
        else
          value = Statistic.lead_speed_grade_for(record, interval: interval, time_start: time_start)
        end
        stats[key] ||= []
        stats[key] << {
          type: key,
          label: record.name,
          id: record.id,
          value: value,
        }
      end
    end
    return stats
  end

  def lead_states
    skope = apply_skope(Lead)
    if @start_date.present? && @end_date.present?
      skope = skope.where(leads: { first_comm: @start_date..@end_date })
    end
    return skope.group(:state).count
  end

  def lead_states_json
    _lead_states = lead_states
    state_order = Lead.aasm.states.map(&:name).map(&:to_s)
    out = state_order.map do |state_name|
      {label: state_name.humanize, val: ( _lead_states[state_name] || 0 ), id: state_name}
    end
    return out.select{|s| s[:val] > 0}
  end

  def lead_sources
    skope = apply_skope(Lead)
    if @start_date.present? && @end_date.present?
      skope = skope.where(first_comm: @start_date..@end_date)
    end
    skope.group(:lead_source_id).count
    return skope.joins("inner join lead_sources on leads.lead_source_id = lead_sources.id").group("concat(lead_sources.name, ' ' , leads.referral)").count
  end

  def lead_sources_conversion_json
    _filter_sql = filter_sql
    converted_states = %w{resident exresident}
    converted_states_sql = "leads.state IN (%s)" % converted_states.map{|s| "'#{s}'"}.join(',')

    sql=<<-EOS
      SELECT
        (array_agg(total_counts.source_id))[1] as source_id,
        total_counts.source_name as source_name,
        SUM(total_counts.total_count)::INTEGER AS total_count,
        SUM(COALESCE(converted_counts.converted_count, 0))::INTEGER AS converted_count
      FROM (
        SELECT
          (array_agg(lead_sources.id))[1] AS source_id,
          coalesce(leads.referral, lead_sources.name) AS source_name,
          count(*) AS total_count
        FROM leads
          JOIN lead_sources ON leads.lead_source_id = lead_sources.id
        WHERE NOT (leads.state = 'invalidated' AND leads.classification = 2)#{ " AND #{_filter_sql}" if _filter_sql.present?}
        GROUP BY coalesce(leads.referral, lead_sources.name)
      ) total_counts
      LEFT JOIN (
        SELECT
          coalesce(leads.referral, lead_sources.name) AS source_name,
          count(*) AS converted_count
        FROM leads
          JOIN lead_sources ON leads.lead_source_id = lead_sources.id
        WHERE (#{converted_states_sql}) AND NOT (leads.state = 'invalidated' AND leads.classification = 2)#{ " AND #{_filter_sql}" if _filter_sql.present?}
        GROUP BY coalesce(leads.referral, lead_sources.name)
      ) converted_counts
       ON total_counts.source_name = converted_counts.source_name
      GROUP BY total_counts.source_name;
EOS

    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      next if record["source_name"] == 'Null'
      {
        label: ( ( record["source_name"] || '' ).empty? ? 'Unknown' : record["source_name"] ).strip,
        val: {
                Total: record["total_count"] || 0,
                Converted: record["converted_count"] || 0
             },
        id: record["source_id"]
      }
    end.compact

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
      WHERE NOT (leads.state = 'invalidated' AND leads.classification = 2)#{ " AND #{_filter_sql}" if _filter_sql.present?}
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
    if @start_date.present? && @end_date.present?
      skope = skope.where(first_comm: @start_date..@end_date)
    end
    skope.
      where(state: 'open').
      order(first_comm: "asc")
  end

  def open_leads_json
    {
      total: open_leads.count,
      count: open_leads.limit(10).count,
      series: open_leads.limit(10).map do |lead|
          {
            id: lead.id,
            label: lead.name,
            created_at: lead.first_comm.present? ? distance_of_time_in_words(lead.first_comm, DateTime.current) : 'No communication',
            url: "/leads/#{lead.id}",
            priority: lead.priority,
            property_id: lead.property_id,
            source: [lead.source&.name, lead.referral].compact.uniq.join(' ')
          }
        end
    }
  end

  def agent_status_json
    skope = User.active.where(id: statistics_collection[:agent].pluck(:id))
    start_date = (Date.current - 7.days).beginning_of_day.strftime("%Y-%m-%d")
    end_date = DateTime.current.strftime("%Y-%m-%d")

    return {
        series: skope.map do |user|
          {
            id: user.id,
            label: user.name,
            total_score: user.score(property_ids: @property_ids),
            weekly_score: user.weekly_score(property_ids: @property_ids),
            tasks_completed: user.tasks_completed(property_ids: @property_ids).count,
            tasks_pending: user.tasks_pending(property_ids: @property_ids).count,
            task_completion_rate: user.task_completion_rate(property_ids: @property_ids),
            worked_leads: user.worked_leads(start_date: start_date, end_date: end_date, property_ids: @property_ids).count,
            closed_leads: user.closed_leads(start_date: start_date, end_date: end_date, property_ids: @property_ids).count,
            url: "/users/#{user.id}",
            start_date: start_date,
            end_date: end_date
          }
        end
      }
  end

  def recent_activity_json(start_date: 2.days.ago.beginning_of_day, end_date: DateTime.current)
    activity = []
    activity += completed_tasks_json(start_date: start_date, end_date: end_date)
    activity += messages_sent_json(start_date: start_date, end_date: end_date)
    activity += lead_state_changed_records_json(start_date: start_date, end_date: end_date)

    # Sort and limit to 50 results
    activity = activity.sort{|x,y| y["raw_date"] <=> x["raw_date"]}[0..19]
    return activity
  end

  def notes_created(start_date: 2.days.ago.beginning_of_day, end_date: DateTime.current)
    notes = Note.where( notable_type: 'Lead', created_at: (start_date..end_date)).comments
    if filter_by_agent?
      notes = notes.where(user_id: @user_ids)
    end
    if filter_by_property?
      notes = notes.joins("INNER JOIN team_users ON team_users.user_id = notes.user_id INNER JOIN teams ON team_users.team_id = teams.id INNER JOIN properties ON ( properties.team_id = teams.id AND properties.id IN #{property_ids_sql} )")
    end
    return notes
  end

  def notes_created_json(start_date: 2.days.ago.beginning_of_day, end_date: DateTime.current)
    return notes_created(start_date: start_date, end_date: end_date).map{|note|
      ActivityEntry.new(
        entry_type: 'Note',
        raw_date: note.created_at,
        date: note.created_at.strftime("%h %d %I:%M%p"),
        description: ("" % [ ]),
        link: nil,
        lead_name: note.notable.name,
        agent_name: note.user.try(:name),
        agent_id: note.user_id ,
        lead_id: note.notable.id
      ).to_h
    }
  end


  def completed_tasks(start_date: 48.hours.ago, end_date: DateTime.current)
    # Completed Lead tasks
    tasks = ScheduledAction.
      where(
        state: [:completed, :completed_retry],
        completed_at: (start_date..end_date),
        target_type: 'Lead',
        user_id: statistics_collection[:agent].pluck(:id)
    )
    return tasks.order(updated_at: :desc).limit(10)
  end

  def completed_tasks_json(start_date: 48.hours.ago, end_date: DateTime.current)
    return completed_tasks(start_date: start_date, end_date: end_date).map{|scheduled_action|
      desc = scheduled_action.activity_summary
      ActivityEntry.new(
        entry_type: 'Task',
        raw_date: scheduled_action.completed_at,
        date: scheduled_action.completed_at.strftime("%h %d %I:%M%p"),
        link: "/scheduled_actions/#{scheduled_action.id}/completion_form",
        description: desc,
        lead_name: scheduled_action.target.name,
        lead_id: scheduled_action.target_id,
        agent_name: scheduled_action.user.try(:name),
        agent_id: scheduled_action.user_id
      ).to_h
    }
  end

  def messages_sent(start_date: 48.hours.ago, end_date: DateTime.current)
    messages = Message.where(
      delivered_at: (start_date..end_date),
      messageable_type: 'Lead',
      user_id: statistics_collection[:agent].pluck(:id)
    )
    return messages.order(created_at: :desc).limit(10)
  end

  def messages_sent_json(start_date: 48.hours.ago, end_date: DateTime.current)
    return messages_sent(start_date: start_date, end_date: end_date).map{|message|
      ActivityEntry.new(
        entry_type: 'Message',
        raw_date: message.delivered_at,
        date: message.delivered_at.strftime("%h %d %I:%M%p"),
        link: "/messages/#{message.id}",
        description: 'Correspondence with Lead',
        lead_name: message.messageable.name,
        lead_id: message. messageable_id,
        agent_name: message.user.try(:name),
        agent_id: message.user_id
      ).to_h
    }
  end

  def lead_state_changed_records(start_date: 48.hours.ago, end_date: DateTime.current)
    transitions = LeadTransition.includes(:lead).
      where(
        created_at: start_date..end_date,
        leads: { 
          user_id: statistics_collection[:agent].pluck(:id)
        }
      ).
      where.not(last_state: 'none')
    return transitions.order(updated_at: :desc).limit(10)
  end

  def lead_state_changed_records_json(start_date: 48.hours.ago, end_date: DateTime.current)
    return lead_state_changed_records(start_date: start_date, end_date: end_date).map{|rec|
      ActivityEntry.new(
        entry_type: 'Lead State',
        raw_date: rec.created_at,
        date: rec.created_at.strftime("%h %d %I:%M%p"),
        link: "/leads/#{rec.lead_id}",
        description: "Lead Progressed from %s to %s" % [rec.last_state.humanize, rec.current_state.humanize],
        lead_name: rec.lead.name,
        lead_id: rec.lead_id,
        agent_name: ( rec.lead.user.try(:name) || 'No Agent' ),
        agent_id: rec.lead.user_id
      ).to_h
    }.compact
  end

  def response_times_json(start_date: 48.hours.ago, end_date: DateTime.current)
    _filter_sql = filter_sql
    sql=<<-EOS
      SELECT
        agent_id,
        agent_name,
        count(CASE WHEN since_last <= 60 * 5 THEN 1 END) AS "5 minutes",
     -- count(CASE WHEN since_last > 60 * 5 AND since_last <= 60 * 10 THEN 1 END) AS "10 minutes",
        count(CASE WHEN since_last > 60 * 10 AND since_last <= 60 * 30 THEN 1 END) AS "30 minutes",
        count(CASE WHEN since_last > 60 * 30 AND since_last <= 3600 THEN 1 END) AS "1 hour",
        count(CASE WHEN since_last > 3600 AND since_last <= 3600 * 2 THEN 1 END) AS "2 hours",
        count(CASE WHEN since_last > 3600 * 2 AND since_last <= 3600 * 4 THEN 1 END) AS "4 hours",
        count(CASE WHEN since_last > 3600 * 4 AND since_last <= 3600 * 8 THEN 1 END) AS "8 hours",
        count(CASE WHEN since_last > 3600 * 8 THEN 1 END) AS ">8 hours"
     -- count(CASE WHEN since_last > 3600 * 8 AND since_last <= 3600 * 24 THEN 1 END) AS "1 day",
     -- count(CASE WHEN since_last > 86400 AND since_last <= 86400 * 2 THEN 1 END) AS "2 days",
     -- count(CASE WHEN since_last > 86400 * 2 THEN 1 END) AS ">2 days"
      FROM (
        SELECT
          messages.user_id AS agent_id,
          concat(user_profiles.first_name, ' ', user_profiles.last_name) AS agent_name,
          user_profiles.last_name,
          user_profiles.first_name,
          messages.since_last
        FROM messages
        INNER JOIN users
          ON messages.user_id = users.id
        INNER JOIN user_profiles
          ON user_profiles.user_id = users.id
        INNER JOIN leads
          ON messages.messageable_id = leads.id AND messages.messageable_type = 'Lead'
        #{ "WHERE #{_filter_sql}" if _filter_sql.present?}
      ) AS responsetimes
      GROUP BY agent_id, agent_name
      ORDER BY agent_name ASC
EOS

    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      {
        label: ( ( record["agent_name"] || '' ).empty? ? 'Unknown' : record["agent_name"] ).strip,
        val: {
              "5 minutes": record["5 minutes"],
              #"10 minutes": record["10 minutes"],
              "30 minutes": record["30 minutes"],
              "1 hour": record["1 hour"],
              "2 hours": record["2 hours"],
              "4 hours": record["4 hours"],
              "8 hours": record["8 hours"],
              ">8 hours": record[">8 hours"]
            # "1 day": record["1 day"],
            # "2 days": record["2 days"],
            # ">2 days": record[">2 days"]
             },
        id: record["agent_id"]
      }
    end

    return result
  end

  def property_engagement_stats_all_time
    sql=<<-EOS
      SELECT
        properties.name AS property_name,
        work_counts.count AS work_count,
        message_counts.sent_messages AS sent_messages,
        lead_counts.open_leads AS open_leads
      FROM properties
      LEFT JOIN
        (
          SELECT
            properties.id AS property_id,
            COUNT(lead_transitions.id) AS count
          FROM properties
          LEFT JOIN property_users
            ON property_users.property_id = properties.id
          LEFT JOIN users
            ON property_users.user_id = users.id
          LEFT JOIN leads
            ON leads.user_id = users.id
          LEFT JOIN lead_transitions
            ON lead_transitions.lead_id = leads.id
            AND lead_transitions.last_state = 'open'
            AND lead_transitions.current_state = 'prospect'
           GROUP BY properties.id
        ) AS work_counts
      ON work_counts.property_id = properties.id
      LEFT JOIN
       (
          SELECT
            properties.id AS property_id,
            COUNT(messages.id) AS sent_messages
          FROM properties
          LEFT JOIN property_users
            ON property_users.property_id = properties.id
          LEFT JOIN users
            ON property_users.user_id = users.id
          LEFT JOIN messages
            ON messages.user_id = users.id
            AND messages.incoming = false
          GROUP BY properties.id		
       ) AS message_counts
       ON message_counts.property_id = properties.id
      LEFT JOIN
        (
          SELECT
            properties.id AS property_id,
            COUNT(leads.id) AS open_leads
          FROM properties
          LEFT JOIN leads
            ON leads.property_id = properties.id
            AND leads.state = 'open'
          GROUP BY properties.id
        ) AS lead_counts
      ON lead_counts.property_id = properties.id
      WHERE
        properties.active = true
      ORDER BY
        properties.name;
    EOS
    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      [record['property_name'], record['work_count'], record['sent_messages'], record['open_leads']]
    end
  end


  def property_engagement_stats_all_time_csv
    CSV.generate do |csv|
      csv << ['Property Name', 'Leads Worked', 'Messages Sent', 'Open Leads']
      property_engagement_stats_all_time.each do |record|
        csv << record
      end
    end
  end

  def property_engagement_stats_by_month(year=nil)
    year ||= Date.current.year
    sql=<<-EOS
      -- Engagement stats by Property by Month
      SELECT
        to_char(series, 'YYYY/MM') AS report_date,
        properties.name AS property_name,
        COALESCE(work_counts.count,0) AS work_count,
        COALESCE(message_counts.sent_messages,0) AS sent_messages
      FROM generate_series('#{year}-01-01'::date, '#{year}-12-31'::date, '1 month'::interval ) AS series
      LEFT JOIN properties ON 1=1
      LEFT JOIN
        (
          SELECT
            properties.id AS property_id,
            to_char(lead_transitions.created_at, 'YYYY/MM') AS report_date,
            COUNT(lead_transitions.id) AS count
          FROM properties
          LEFT JOIN property_users
            ON property_users.property_id = properties.id
          LEFT JOIN users
            ON property_users.user_id = users.id
          LEFT JOIN leads
            ON leads.user_id = users.id
          LEFT JOIN lead_transitions
            ON lead_transitions.lead_id = leads.id
            AND lead_transitions.last_state = 'open'
            AND lead_transitions.current_state = 'prospect'
           GROUP BY
            properties.id,
            to_char(lead_transitions.created_at, 'YYYY/MM')
        ) AS work_counts
      ON
        work_counts.property_id = properties.id
        AND work_counts.report_date = to_char(series, 'YYYY/MM')
      LEFT JOIN
       (
          SELECT
            properties.id AS property_id,
            to_char(messages.created_at, 'YYYY/MM') AS report_date,
            COUNT(messages.id) AS sent_messages
          FROM properties
          LEFT JOIN property_users
            ON property_users.property_id = properties.id
          LEFT JOIN users
            ON property_users.user_id = users.id
          LEFT JOIN messages
            ON messages.user_id = users.id
            AND messages.incoming = false
          GROUP BY
            properties.id,
            to_char(messages.created_at, 'YYYY/MM')
       ) AS message_counts
       ON
        message_counts.property_id = properties.id
        AND message_counts.report_date = to_char(series, 'YYYY/MM')
      WHERE
        properties.active = true
      ORDER BY
        properties.name,
        to_char(series, 'YYYY/MM');
    EOS
    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      [record['report_date'], record['property_name'], record['work_count'], record['sent_messages']]
    end
  end

  def property_engagement_stats_by_month_csv(year=nil)
    CSV.generate do |csv|
      csv << ['Month', 'Property Name', 'Leads Worked', 'Messages Sent']
      property_engagement_stats_by_month(year).each do |record|
        csv << record
      end
    end
  end

  def agent_engagement_stats_all_time
    sql=<<-EOS
      SELECT
        user_profiles.first_name AS first_name,
        user_profiles.last_name AS last_name,
        users.email AS email,
        users.last_sign_in_at,
        work_counts.count AS work_count,
        message_counts.sent_messages AS sent_messages,
        impressions.pageviews AS pageviews,
        users.id AS user_id
      FROM users
      INNER JOIN user_profiles
        ON user_profiles.user_id = users.id
      LEFT JOIN
        (
          SELECT
            users.id AS user_id,
            COUNT(lead_transitions.id) AS count
          FROM users
          LEFT JOIN leads
            ON leads.user_id = users.id
          LEFT JOIN lead_transitions
            ON lead_transitions.lead_id = leads.id
            AND lead_transitions.last_state = 'open'
            AND lead_transitions.current_state = 'prospect'
           GROUP BY users.id
        ) AS work_counts
        ON work_counts.user_id = users.id
      LEFT JOIN
       (
          SELECT
            users.id AS user_id,
            COUNT(messages.id) AS sent_messages
          FROM users
          LEFT JOIN messages
            ON messages.user_id = users.id
            AND messages.incoming = false
          GROUP BY users.id		
       ) AS message_counts
       ON message_counts.user_id = users.id
      LEFT JOIN
       (
        SELECT
          users.id AS user_id,
          COUNT(user_impressions.id) AS pageviews
        FROM users
        LEFT JOIN user_impressions
          ON user_impressions.user_id = users.id
        GROUP BY users.id
       ) AS impressions
       ON impressions.user_id = users.id
      WHERE
        users.deactivated = false
      ORDER BY
        user_profiles.last_name, user_profiles.first_name;
    EOS
    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      [record['first_name'], record['last_name'], record['email'], record['last_sign_in_at'], record['work_count'], record['sent_messages'], record['pageviews']]
    end
  end

  def agent_engagement_stats_all_time_csv
    CSV.generate do |csv|
      csv << ['First Name', 'Last Name', 'Email', 'Last Signin', 'Leads Worked', 'Messages Sent', 'Page Views']
      agent_engagement_stats_all_time.each do |record|
        csv << record
      end
    end
  end

  def agent_engagement_stats_by_month(year=nil)
    year ||= Date.current.year
    sql=<<-EOS
      SELECT
        to_char(series, 'YYYY/MM') AS report_date,
        user_profiles.first_name AS first_name,
        user_profiles.last_name AS last_name,
        users.email AS email,
        COALESCE(work_counts.count,0) AS work_count,
        COALESCE(message_counts.sent_messages,0) AS sent_messages
      FROM generate_series('#{year}-01-01'::date, '#{year}-12-31'::date, '1 month'::interval ) AS series
      LEFT JOIN users ON 1=1
      LEFT JOIN user_profiles
        ON user_profiles.user_id = users.id
      LEFT JOIN
        (
          SELECT
            users.id AS user_id,
            to_char(lead_transitions.created_at, 'YYYY/MM') AS report_date,
            COUNT(lead_transitions.id) AS count
          FROM users
          LEFT JOIN leads
            ON leads.user_id = users.id
          LEFT JOIN lead_transitions
            ON lead_transitions.lead_id = leads.id
            AND lead_transitions.last_state = 'open'
            AND lead_transitions.current_state = 'prospect'
          GROUP BY
            users.id,
            to_char(lead_transitions.created_at, 'YYYY/MM')
        ) AS work_counts
        ON
          work_counts.user_id = users.id
          AND work_counts.report_date = to_char(series, 'YYYY/MM')
      LEFT JOIN
       (
          SELECT
            users.id AS user_id,
            to_char(messages.created_at, 'YYYY/MM') AS report_date,
            COUNT(messages.id) AS sent_messages
          FROM users
          LEFT JOIN messages
            ON messages.user_id = users.id
            AND messages.incoming = false
          GROUP BY
            users.id,
            to_char(messages.created_at, 'YYYY/MM')
       ) AS message_counts
       ON
        message_counts.user_id = users.id
        AND message_counts.report_date = to_char(series, 'YYYY/MM')
      WHERE
        users.deactivated = false
      ORDER BY
        user_profiles.last_name,
        user_profiles.first_name,
        to_char(series, 'YYYY/MM');
    EOS
    raw_result = ActiveRecord::Base.connection.execute(sql).to_a
    result = raw_result.map do |record|
      [record['report_date'], record['first_name'], record['last_name'], record['email'], record['work_count'], record['sent_messages']]
    end
  end

  def agent_engagement_stats_by_month_csv(year=nil)
    CSV.generate do |csv|
      csv << ['Month', 'First Name', 'Last Name', 'Email', 'Leads Worked', 'Messages Sent']
      agent_engagement_stats_by_month(year).each do |record|
        csv << record
      end
    end
  end

  private

  def filter_by_property?
    return (@property_ids.present? || @team_ids.present?)
  end

  def filter_by_agent?
    return @user_ids.present?
  end

  def property_ids_for_filter
    return @property_ids.present? ? @property_ids :
      ( @teams.present? ? Property.where(team_id: @team_ids).order("name ASC").map(&:id) : [] )
  end

  def property_ids_sql
    return "(#{property_ids_for_filter.map{|i| "'#{i}'"}.join(',')})"
  end

  def user_ids_sql
    return "(#{@user_ids.map{|i| "'#{i}'"}.join(',')})"
  end

  def team_ids_sql
    return "(#{@team_ids.map{|i| "'#{i}'"}.join(',')})"
  end

  def filter_sql
    filters = []
    if @user_ids.present?
      filters << "leads.user_id in #{user_ids_sql}"
    end
    if property_ids_for_filter.present?
      filters << "leads.property_id in #{property_ids_sql}"
    end
    if @start_date.present? && @end_date.present?
      filters << "leads.first_comm BETWEEN '%s' AND '%s'" % [@start_date.utc.to_s, @end_date.utc.to_s]
    end
    return filters.map{|f| "(#{f})"}.join(" AND ")
  end

  def lead_transition_filter_sql
    filters = []
    if @user_ids.present?
      filters << "leads.user_id in #{user_ids_sql}"
    end
    if property_ids_for_filter.present?
      filters << "leads.property_id in #{property_ids_sql}"
    end
    if @start_date.present? && @end_date.present?
      filters << "lead_transitions.created_at BETWEEN '%s' AND '%s'" % [@start_date.utc.to_s, @end_date.utc.to_s]
    end
    return filters.map{|f| "(#{f})"}.join(" AND ")
  end

  def apply_skope(skope)
    if @user_ids.present?
      skope = skope.where(user_id: @user_ids)
    end
    if property_ids_for_filter.present?
      skope = skope.where(property_id: property_ids_for_filter)
    end
    return skope
  end

  def get_user_ids(users)
    Array(users).map{|u| u.is_a?(User) ? u.id : u }
  end

  def get_property_ids(properties)
    Array(properties).map do |p|
      case p
      when Property
        p.id
      when nil, ''
        nil
      when String
        p
      else
        nil
      end
    end.compact
  end

  def get_team_ids(teams)
    Array(teams).map{|t| t.is_a?(Team) ? t.id : t }
  end

  # Helper method to determine which timezone to use
  def determine_timezone
    if @timezone.present?
      # Try to use the provided timezone (from browser)
      zone = ActiveSupport::TimeZone[@timezone]
      return zone if zone
    end
    # Fallback to server's configured timezone
    Time.zone
  end

  # Helper method to get current time in the determined timezone
  def timezone_current
    tz = determine_timezone
    tz ? Time.current.in_time_zone(tz) : DateTime.current
  end

  def get_date_range(filters)
    date_range = Array(filters.fetch(:date_range, nil))
    if date_range.length >= 1
      date_range = date_range.select{|r| r!= 'all_time' }.last
    else
      date_range = date_range.last
    end

    # Use timezone-aware current time if timezone is provided
    tz = determine_timezone

    if tz
      # Use timezone-aware calculations
      Time.use_zone(tz) do
        current_time = Time.current
        end_date = current_time

        case date_range
        when [], nil, 'all_time'
          start_date = nil
          end_date = nil
          date_range = nil
        when 'today'
          start_date = current_time.beginning_of_day
        when 'week'
          start_date = current_time - 1.week
        when 'last_week'
          start_date = current_time.beginning_of_week - 1.week
          end_date = current_time.end_of_week - 1.week
        when '2weeks'
          start_date = current_time - 2.weeks
        when 'month'
          start_date = current_time - 1.month
        when 'last_month'
          start_date = current_time.beginning_of_month - 1.month
          end_date = current_time.end_of_month - 1.month
        when '3months'
          start_date = current_time - 3.months
        when 'last_quarter'
          this_year = current_time.year
          case current_time.month
          when 1,2,3
            start_date = tz.parse("#{this_year}-01-01").beginning_of_day
            end_date = tz.parse("#{this_year}-03-31").end_of_day
          when 4,5,6
            start_date = tz.parse("#{this_year}-04-01").beginning_of_day
            end_date = tz.parse("#{this_year}-06-30").end_of_day
          when 7,8,9
            start_date = tz.parse("#{this_year}-07-01").beginning_of_day
            end_date = tz.parse("#{this_year}-09-30").end_of_day
          when 10,11,12
            start_date = tz.parse("#{this_year}-10-01").beginning_of_day
            end_date = tz.parse("#{this_year}-12-31").end_of_day
          end
        when 'year'
          start_date = current_time - 1.year
        when 'last_year'
          start_date = current_time.beginning_of_year - 1.year
          end_date = current_time.end_of_year - 1.year
        when 'custom'
          # Handle custom date range with user-provided start and end dates
          # Handle both array and string formats for start_date and end_date
          start_date_value = filters[:start_date].is_a?(Array) ? filters[:start_date].first : filters[:start_date]
          end_date_value = filters[:end_date].is_a?(Array) ? filters[:end_date].first : filters[:end_date]

          start_date = start_date_value.present? ? tz.parse(start_date_value).beginning_of_day : 99.years.ago
          end_date = end_date_value.present? ? tz.parse(end_date_value).end_of_day : current_time
        else
          date_range = 'custom'
          start_date = tz.parse(filters.fetch(:start_date, '')) rescue 99.years.ago
          end_date = tz.parse(filters.fetch(:end_date, '')) rescue current_time
        end

        return [date_range, start_date, end_date]
      end
    else
      # Fallback to original behavior if no timezone
      end_date = DateTime.current
      case date_range
      when [], nil, 'all_time'
        start_date = nil
        end_date = nil
        date_range = nil
      when 'today'
        start_date = DateTime.current.beginning_of_day
      when 'week'
        start_date = DateTime.current - 1.week
      when 'last_week'
        start_date = DateTime.current.beginning_of_week - 1.week
        end_date = DateTime.current.end_of_week - 1.week
      when '2weeks'
        start_date = DateTime.current - 2.weeks
      when 'month'
        start_date = DateTime.current - 1.month
      when 'last_month'
        start_date = DateTime.current.beginning_of_month - 1.month
        end_date = DateTime.current.end_of_month - 1.month
      when '3months'
        start_date = DateTime.current - 3.months
      when 'last_quarter'
        this_year = Date.current.year
        case Date.current.month
        when 1,2,3
          start_date = DateTime.new(this_year,1,1)
          end_date = DateTime.new(this_year,3,31)
        when 4,5,6
          start_date = DateTime.new(this_year,4,1)
          end_date = DateTime.new(this_year,6,30)
        when 7,8,9
          start_date = DateTime.new(this_year,7,1)
          end_date = DateTime.new(this_year,9,30)
        when 10,11,12
          start_date = DateTime.new(this_year,10,1)
          end_date = DateTime.new(this_year,12,31)
        end
      when 'year'
        start_date = DateTime.current - 1.year
      when 'last_year'
        start_date = DateTime.current.beginning_of_year - 1.year
        end_date = DateTime.current.end_of_year - 1.year
      when 'custom'
        # Handle custom date range with user-provided start and end dates
        # Handle both array and string formats for start_date and end_date
        start_date_value = filters[:start_date].is_a?(Array) ? filters[:start_date].first : filters[:start_date]
        end_date_value = filters[:end_date].is_a?(Array) ? filters[:end_date].first : filters[:end_date]

        start_date = start_date_value.present? ? Date.parse(start_date_value).beginning_of_day : 99.years.ago
        end_date = end_date_value.present? ? Date.parse(end_date_value).end_of_day : DateTime.current
      else
        date_range = 'custom'
        start_date = Date.parse(filters.fetch(:start_date, '')) rescue 99.years.ago
        end_date = Date.parse(filters.fetch(:end_date, '')) rescue DateTime.current
      end
      return [date_range, start_date, end_date]
    end
  end

end
