class ProspectStats
  attr_reader :options

  def initialize(options={})
    @options = options
    @voyager_source = LeadSource.where(slug: 'YardiVoyager').first
  end

  def property_stats
    Property.order(name: 'asc').map do |property|
      {
        "Name": property.name,
        "ID": property_voyager_id(property),
        "Stats": {
          "Prospects10": prospect_count(property, 10),
          "Prospects30": prospect_count(property, 30),
          "Prospects180": prospect_count(property, 180),
          "Prospects365": prospect_count(property, 365),
          "Closings10": closing_rate(property, 10),
          "Closings30": closing_rate(property, 30),
          "Closings180": closing_rate(property, 180),
          "Closings365": closing_rate(property, 365),
          "Conversions10": converstion_rate(property, 10),
          "Conversions30": converstion_rate(property, 30),
          "Conversions180": converstion_rate(property, 180),
          "Conversions365": converstion_rate(property, 365)
        }
      }
    end.compact
  end

  def agent_stats
    User.includes(:profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC").map do |user|
      next unless user.leads.count > 0
      {
        "Name": user.name,
        "ID": user.id,
        "Stats": {
          "Prospects10": prospect_count(user, 10),
          "Prospects30": prospect_count(user, 30),
          "Prospects180": prospect_count(user, 180),
          "Prospects365": prospect_count(user, 365),
          "Closings10": closing_rate(user, 10),
          "Closings30": closing_rate(user, 30),
          "Closings180": closing_rate(user, 180),
          "Closings365": closing_rate(user, 365),
          "Conversions10": converstion_rate(user, 10),
          "Conversions30": converstion_rate(user, 30),
          "Conversions180": converstion_rate(user, 180),
          "Conversions365": converstion_rate(user, 365)
        }
      }
    end.compact
  end

  def team_stats
    Team.order(name: 'asc').map do |team|
      next unless team.leads.count > 0
      {
        "Name": team.name,
        "ID": team.id,
        "Stats": {
          "Prospects10": prospect_count(team, 10),
          "Prospects30": prospect_count(team, 30),
          "Prospects180": prospect_count(team, 180),
          "Prospects365": prospect_count(team, 365),
          "Closings10": closing_rate(team, 10),
          "Closings30": closing_rate(team, 30),
          "Closings180": closing_rate(team, 180),
          "Closings365": closing_rate(team, 365),
          "Conversions10": converstion_rate(team, 10),
          "Conversions30": converstion_rate(team, 30),
          "Conversions180": converstion_rate(team, 180),
          "Conversions365": converstion_rate(team, 365)
        }
      }
    end.compact
  end

  private

  def property_voyager_id(property)
    raise "Missing LeadSource: 'YardiVoyager'" unless @voyager_source.present?
    return property.listing_code(@voyager_source)
  end

  def prospect_count(skope, window)
    return skope.leads.
      where(created_at: window.days.ago..DateTime.now).
      count
  end

  def converstion_rate(skope, window)
    count = skope.leads.includes(:lead_transitions).
      where(lead_transitions: {
        current_state: 'application',
        created_at: window.days.ago..DateTime.now
      }).count
    return calculate_lead_pctg(count, skope, window)
  end

  def closing_rate(skope, window)
    count = skope.leads.includes(:lead_transitions).
      where(lead_transitions: {
        current_state: 'movein',
        created_at: window.days.ago..DateTime.now
      }).count
    return calculate_lead_pctg(count, skope, window)
  end

  def calculate_lead_pctg(count, skope, window)
    if count > 0
      rate = ( ( count.to_f / prospect_count(skope,window).to_f ) * 100.0).round(1)
    else
      rate = 0.0
    end
    return rate
  end

end
