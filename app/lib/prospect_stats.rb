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
          "Prospect10": prospect_count(property, 10),
          "Prospect30": prospect_count(property, 30),
          "Prospect180": prospect_count(property, 180),
          "Prospect365": prospect_count(property, 365),
          "Closing10": closing_count(property, 10),
          "Closing30": closing_count(property, 30),
          "Closing180": closing_count(property, 180),
          "Closing365": closing_count(property, 365),
          "Conversion10": conversion_count(property, 10),
          "Conversion30": conversion_count(property, 30),
          "Conversion180": conversion_count(property, 180),
          "Conversion365": conversion_count(property, 365)
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
          "Prospect10": prospect_count(user, 10),
          "Prospect30": prospect_count(user, 30),
          "Prospect180": prospect_count(user, 180),
          "Prospect365": prospect_count(user, 365),
          "Closing10": closing_count(user, 10),
          "Closing30": closing_count(user, 30),
          "Closing180": closing_count(user, 180),
          "Closing365": closing_count(user, 365),
          "Conversion10": conversion_count(user, 10),
          "Conversion30": conversion_count(user, 30),
          "Conversion180": conversion_count(user, 180),
          "Conversion365": conversion_count(user, 365)
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
          "Prospect10": prospect_count(team, 10),
          "Prospect30": prospect_count(team, 30),
          "Prospect180": prospect_count(team, 180),
          "Prospect365": prospect_count(team, 365),
          "Closing10": closing_count(team, 10),
          "Closing30": closing_count(team, 30),
          "Closing180": closing_count(team, 180),
          "Closing365": closing_count(team, 365),
          "Conversion10": conversion_count(team, 10),
          "Conversion30": conversion_count(team, 30),
          "Conversion180": conversion_count(team, 180),
          "Conversion365": conversion_count(team, 365)
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

  def conversion_count(skope, window)
    return skope.leads.includes(:lead_transitions).
      where(lead_transitions: {
        current_state: 'application',
        created_at: window.days.ago..DateTime.now
      }).count
  end

  def closing_count(skope, window)
    return skope.leads.includes(:lead_transitions).
      where(lead_transitions: {
        current_state: 'movein',
        created_at: window.days.ago..DateTime.now
      }).count
  end

end
