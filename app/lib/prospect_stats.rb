class ProspectStats
  CACHE_DURATION = 1.hour
  CLOSING_STATE = 'application'
  CONVERSION_STATE = 'showing'

  attr_reader :ids, :filters, :end_date
  attr_accessor :caching

  def initialize(ids: nil, filters: {})
    @ids = ids
    @caching = true
    @refresh = false
    @cache_data = {}
    @voyager_source = voyager_source
    @filters = filters
    @end_date = ( DateTime.parse(filters[:date]).end_of_day rescue DateTime.now )
  end

  def refresh_cache
    old_cache_setting = @caching
    @caching = true
    @refresh = true
    property_stats
    team_stats
    agent_stats
    @refresh = false
    @caching = old_cache_setting
    return true
  end

  def property_stats
    with_cache('property_stats') do
      out = []
      skope = Property.active.includes(:listings)
      skope = skope.where(property_listings: {code: @ids, source_id: @voyager_source.id}) if @ids.present?
      skope.order("properties.name ASC").each do |property|
        out <<
        {
          "Name": property.name,
          "ID": property_voyager_id(property),
          "BlueskyID": property.id,
          "ReportDate": DateTime.now,
          "EndDate": @end_date,
          "Stats": {
            "Prospects365_all": prospect_count_all(property, 365),
            "Prospects365": prospect_count(property, 365),
            "Prospects180_all": prospect_count_all(property, 180),
            "Prospects180": prospect_count(property, 180),
            "Prospects30_all": prospect_count_all(property, 30),
            "Prospects30": prospect_count(property, 30),
            "Prospects10_all": prospect_count_all(property, 10),
            "Prospects10": prospect_count(property, 10),
            "Conversions365": conversion_rate(property, 365),
            "Conversions180": conversion_rate(property, 180),
            "Conversions30": conversion_rate(property, 30),
            "Conversions10": conversion_rate(property, 10),
            "Closings365": closing_rate(property, 365),
            "Closings180": closing_rate(property, 180),
            "Closings30": closing_rate(property, 30),
            "Closings10": closing_rate(property, 10),
            "UnclaimedLeadsNow": unclaimed_leads_now(property),
            "Tenacity30": "TBD",
            "LeadSpeed30": "TBD"
          }
        }
      end
      out
    end
  end


  def agent_stats
    with_cache('agent_stats') do
      out = []
      skope = User.includes(:profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC")
      skope = skope.where(users: {id: @ids}) if @ids.present?
      skope.each do |user|
        next unless user.leads.count > 0
        out <<
        {
          "Name": user.name,
          "ID": user.id,
          "BlueskyID": user.id,
          "ReportDate": DateTime.now,
          "EndDate": @end_date,
          "Stats": {
            "Prospects365_all": prospect_count_all(user, 365),
            "Prospects365": prospect_count(user, 365),
            "Prospects180_all": prospect_count_all(user, 180),
            "Prospects180": prospect_count(user, 180),
            "Prospects30_all": prospect_count_all(user, 30),
            "Prospects30": prospect_count(user, 30),
            "Prospects10_all": prospect_count_all(user, 10),
            "Prospects10": prospect_count(user, 10),
            "Conversions365": conversion_rate(user, 365),
            "Conversions180": conversion_rate(user, 180),
            "Conversions30": conversion_rate(user, 30),
            "Conversions10": conversion_rate(user, 10),
            "Closings365": closing_rate(user, 365),
            "Closings180": closing_rate(user, 180),
            "Closings30": closing_rate(user, 30),
            "Closings10": closing_rate(user, 10),
            "UnclaimedLeadsNow": unclaimed_leads_now(user),
            "Tenacity30": "TBD",
            "LeadSpeed30": "TBD"
          }
        }
      end
      out
    end
  end

  def team_stats
    with_cache('team_stats') do
      out = []
      skope = Team.order(name: 'asc')
      skope = skope.where(id: @ids) if @ids.present?
      skope.each do |team|
        next unless team.leads.count > 0
        out <<
        {
          "Name": team.name,
          "ID": team.id,
          "BlueskyID": team.id,
          "ReportDate": DateTime.now,
          "EndDate": @end_date,
          "Stats": {
            "Prospects365_all": prospect_count_all(team, 365),
            "Prospects365": prospect_count(team, 365),
            "Prospects180_all": prospect_count_all(team, 180),
            "Prospects180": prospect_count(team, 180),
            "Prospects30_all": prospect_count_all(team, 30),
            "Prospects30": prospect_count(team, 30),
            "Prospects10_all": prospect_count_all(team, 10),
            "Prospects10": prospect_count(team, 10),
            "Conversions365": conversion_rate(team, 365),
            "Conversions180": conversion_rate(team, 180),
            "Conversions30": conversion_rate(team, 30),
            "Conversions10": conversion_rate(team, 10),
            "Closings365": closing_rate(team, 365),
            "Closings180": closing_rate(team, 180),
            "Closings30": closing_rate(team, 30),
            "Closings10": closing_rate(team, 10),
            "UnclaimedLeadsNow": unclaimed_leads_now(team),
            "Tenacity30": "TBD",
            "LeadSpeed30": "TBD"
          }
        }
      end
      out
    end
  end

  private

  def time_window_range(window)
    return time_window_start(window)..@end_date
  end

  def time_window_start(window)
    return @end_date - window.days
  end

  def voyager_source
    return LeadSource.where(slug: 'YardiVoyager').first
  end

  def property_voyager_id(property)
    raise "Missing LeadSource: 'YardiVoyager'" unless @voyager_source.present?
    return property.listing_code(@voyager_source)
  end

  def prospect_count_all(skope, window)
    Rails.logger.info "=== ProspectStats: prospect_count_all #{window}"
    return cache(stat: 'prospect_count_all', skope: skope, window: window) do
      prospect_count_all_scope(skope, window).count
    end
  end

  # Leads for a scope within a time window
  # Excluding residents, vendors, and duplicates
  # NOTE Limitations: will not report Leads without an initial LeadTransition
  def prospect_count_all_scope(skope, window)
    join_sql = "INNER JOIN lead_transitions ON lead_transitions.lead_id = leads.id"
    transition_states_sql = %w{resident exresident}.map{|s| "'#{s}'"}.join(',')
    exclude_lead_states_sql = %w{disqualified abandoned}.map{|s| "'#{s}'"}.join(',')

    condition_sql=<<~SQL
      ( leads.classification IS NULL OR leads.classification = 0)
      AND (leads.state NOT IN (#{exclude_lead_states_sql}))
      AND leads.first_comm BETWEEN ? AND ?
      AND (
       lead_transitions.last_state != 'none'
       OR ( lead_transitions.last_state = 'none'
             AND lead_transitions.current_state NOT IN (#{transition_states_sql})
           )
      )
    SQL

    return skope.leads.
      joins(join_sql).
      where(condition_sql, time_window_start(window), @end_date)
  end

  # Approximate prospect count excluding duplicates
  def prospect_count(skope, window)
    Rails.logger.info "=== ProspectStats: prospect_count #{window}"
    return cache(stat: 'prospect_count', skope: skope, window: window) do
      prospect_ids = prospect_count_all_scope(skope, window).select(:id).map(&:id)
      duplicate_count = DuplicateLead.where(lead_id: prospect_ids).
        select("distinct lead_id").count
      prospect_ids.size - (duplicate_count / 2)
    end
  end

  def conversion_rate(skope, window)
    Rails.logger.info "=== ProspectStats: conversion_rate #{window}"
    return cache(stat: 'conversion_rate', skope: skope, window: window) do
      count = skope.leads.includes(:lead_transitions).
        where(lead_transitions: {
        current_state: CONVERSION_STATE,
        created_at: time_window_range(window)
      }).count
      calculate_lead_pctg(count, skope, window)
    end
  end

  #def conversion_rate_all(skope, window)
    #Rails.logger.info "=== ProspectStats: conversion_rate_all #{window}"
    #return cache(stat: 'conversion_rate_all', skope: skope, window: window) do
      #count = skope.leads.includes(:lead_transitions).
        #where(lead_transitions: {
        #current_state: CONVERSION_STATE,
        #created_at: time_window_range(window)
      #}).count
      #calculate_lead_pctg_all(count, skope, window)
    #end
  #end

  def closing_rate(skope, window)
    Rails.logger.info "=== ProspectStats: closing_rate #{window}"
    return cache(stat: 'closing_rate', skope: skope, window: window) do
      count = skope.leads.includes(:lead_transitions).
        where(lead_transitions: {
        current_state: CLOSING_STATE,
        created_at: time_window_range(window)
      }).count
      calculate_lead_pctg(count, skope, window)
    end
  end

  #def closing_rate_all(skope, window)
    #Rails.logger.info "=== ProspectStats: closing_rate_all #{window}"
    #return cache(stat: 'closing_rate_all', skope: skope, window: window) do
      #count = skope.leads.includes(:lead_transitions).
        #where(lead_transitions: {
        #current_state: CLOSING_STATE,
        #created_at: time_window_range(window)
      #}).count
      #calculate_lead_pctg_all(count, skope, window)
    #end
  #end

  def calculate_lead_pctg(count, skope, window)
    if count > 0
      rate = (count.to_f / prospect_count(skope,window).to_f).round(3)
    else
      rate = 0.0
    end
    return rate
  end

  def unclaimed_leads_now(context)
    case context
    when Team
      skope = Lead.where(user_id: context.members.pluck(&:id))
    else
      skope = context.leads
    end
    skope.where(state: 'open').count
  end

  #def calculate_lead_pctg_all(count, skope, window)
    #if count > 0
      #rate = (count.to_f / prospect_count_all(skope,window).to_f).round(3)
    #else
      #rate = 0.0
    #end
    #return rate
  #end

  def cache(stat:, skope:, window:, &block)
    key = cached_data_key(stat: stat, skope: skope, window: window)
    data = @cache_data[key]
    if data.nil?
      data = @cache_data[cached_data_key(stat: stat, skope: skope, window: window)] = yield
    end
    return data
  end

  def cached_data_key(stat:, skope:, window:)
    klass = skope.try(:class_name) || skope.class.to_s
    identifier = skope.try(:id) || 'all'
    return [klass, identifier, stat, window, @end_date.to_date.to_s].join(':')
  end

  def cache_key(stat='')
    id_hash = Digest::SHA2.hexdigest(stat + @end_date.to_date.to_s + ( @ids || [] ).join(','))
    "ProspectStats-%s" % [id_hash]
  end

  def with_cache(stat, &block)
    if @caching
      Rails.cache.fetch(cache_key(stat), force: @refresh, expires_in: CACHE_DURATION) do
        block.call
      end
    else
      block.call
    end
  end

end
