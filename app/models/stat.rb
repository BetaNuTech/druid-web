class Stat
  attr_reader :user_ids, :property_ids, :team_ids, :users, :properties, :teams, :url
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


  def initialize(filters: {}, url: "/stats/manager")
    @url = url
    @filters = filters
    @user_ids = get_user_ids(filters.fetch(:user_ids, []))
    @property_ids = get_property_ids(filters.fetch(:property_ids, []))
    @team_ids = get_team_ids(filters.fetch(:team_ids,[]))
    @users = User.find(@user_ids)
    @properties = Property.find(@property_ids)
    @teams = Team.find(@team_ids)
  end

  def json_url
    return url + "?filter=true&" + @filters.to_a.compact.inject([]){|memo, obj| memo << ( obj[1] || [] ).map{|f| "#{obj[0]}[]=#{f}" }.join('&') ; memo}.join('&')
  end

  def filters_json
    team_properties = @teams.present? ? Property.where(team_id: @team_ids).order("name ASC") : Property.order("name ASC")
    filter_properties = @properties.present? ? @properties : team_properties
    users = User.includes(:properties).where(properties: {id: filter_properties.map(&:id)}).sort_by(&:last_name)
    return {
      options: {
        _index: ['users', 'properties', 'teams'],
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
        }
      },
      users: @users.map{|user| {label: user.name, val: user.id}},
      properties: @properties.map{|property| {label: property.name, val: property.id}},
      teams: @teams.map{|team| {label: team.name, val: team.id}}
    }
  end

  def lead_states
    skope = apply_skope(Lead)
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
          coalesce(leads.referral, lead_sources.name) AS source_name,
          count(*) AS total_count
        FROM leads
          JOIN lead_sources ON leads.lead_source_id = lead_sources.id
        #{ "WHERE #{_filter_sql}" if _filter_sql.present?}
        GROUP BY ( lead_sources.name, lead_sources.id, leads.referral )
      ) total_counts
      FULL OUTER JOIN (
        SELECT
          coalesce(leads.referral, lead_sources.name) AS source_name,
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
        label: ( record["source_name"].empty? ? 'Unknown' : record["source_name"] ).strip,
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
    if filter_by_property?
      skope = skope.includes(:properties).where(properties: {id: property_ids_for_filter})
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

  def recent_activity_json(start_date: 2.days.ago.beginning_of_day, end_date: DateTime.now)
    activity = []
    activity += completed_tasks_json(start_date: start_date, end_date: end_date)
    activity += messages_sent_json(start_date: start_date, end_date: end_date)
    activity += lead_state_changed_records_json(start_date: start_date, end_date: end_date)
    activity = activity.sort{|x,y| y["raw_date"] <=> x["raw_date"]}
    return activity
  end

  def notes_created(start_date: 2.days.ago.beginning_of_day, end_date: DateTime.now)
    notes = Note.where( notable_type: 'Lead', created_at: (start_date..end_date))
    if @user_ids.present?
      notes = notes.where(user_id: @user_ids)
    end
    if filter_by_property?
      notes = notes.joins("INNER JOIN team_users ON team_users.user_id = notes.user_id INNER JOIN teams ON team_users.team_id = teams.id INNER JOIN properties ON ( properties.team_id = teams.id AND properties.id IN #{property_ids_sql} )")
    end
    return notes
  end

  def notes_created_json(start_date: 2.days.ago.beginning_of_day, end_date: DateTime.now)
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

  def completed_tasks(start_date: 48.hours.ago, end_date: DateTime.now)
    tasks = EngagementPolicyActionCompliance.
        includes(:scheduled_action).
        where( state: [:completed, :completed_retry],
               completed_at: (start_date..end_date),
               scheduled_actions: {target_type: 'Lead'}
             )
    if @user_ids.present?
      tasks = tasks.where(user_id: @user_ids)
    end
    if filter_by_property?
      tasks = tasks.joins("INNER JOIN team_users ON team_users.user_id = engagement_policy_action_compliances.user_id INNER JOIN teams ON team_users.team_id = teams.id INNER JOIN properties ON ( properties.team_id = teams.id AND properties.id IN #{property_ids_sql} )")
    end
    return tasks
  end

  def completed_tasks_json(start_date: 48.hours.ago, end_date: DateTime.now)
    return completed_tasks(start_date: start_date, end_date: end_date).map{|task|
      desc = ( task.scheduled_action.try(:lead_action).try(:description) || '(Unknown Lead Action)' ) + " " + task.memo
      ActivityEntry.new(
        entry_type: 'Task',
        raw_date: task.completed_at,
        date: task.completed_at.strftime("%h %d %I:%M%p"),
        link: "/scheduled_actions/#{task.scheduled_action_id}/completion_form",
        description: ( task.scheduled_action.try(:lead_action).try(:description) || '(Unknown Lead Action)' ) + " " + task.memo,
        lead_name: task.scheduled_action.target.name,
        lead_id: task.scheduled_action.target_id,
        agent_name: task.user.try(:name),
        agent_id: task.user_id
      ).to_h
    }
  end

  def messages_sent(start_date: 48.hours.ago, end_date: DateTime.now)
    messages = Message.where(
      delivered_at: (start_date..end_date),
      messageable_type: 'Lead')
    if @user_ids.present?
      messages = messages.where(user_id: @user_ids)
    end
    if filter_by_property?
      messages = messages.joins("INNER JOIN team_users ON team_users.user_id = messages.user_id INNER JOIN teams ON team_users.team_id = teams.id INNER JOIN properties ON ( properties.team_id = teams.id AND properties.id IN #{property_ids_sql} )")
    end
    return messages
  end

  def messages_sent_json(start_date: 48.hours.ago, end_date: DateTime.now)
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

  def lead_state_changed_records(start_date: 48.hours.ago, end_date: DateTime.now)
    transitions = LeadTransition.where(created_at: start_date..end_date)
    if @user_ids.present? || filter_by_property?
      if filter_by_property?
        transitions = transitions.includes(lead: [:property]).where(properties: {id: [property_ids_for_filter]})
      end
      if @user_ids.present?
        transitions = transitions.includes(:lead).where(leads: {user_id: @user_ids})
      end
    end

    return transitions
  end

  def lead_state_changed_records_json(start_date: 48.hours.ago, end_date: DateTime.now)
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

  private

  def filter_by_property?
    return (@property_ids.present? || @team_ids.present?)
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
    Array(properties).map{|p| p.is_a?(Property) ? p.id : p }
  end

  def get_team_ids(teams)
    Array(teams).map{|t| t.is_a?(Team) ? t.id : t }
  end

end
