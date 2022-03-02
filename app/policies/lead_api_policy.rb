class LeadApiPolicy < ApplicationPolicy
  def index?
    LeadSource.active.map(&:name).include?(record.name)
  end

  def create?
    index?
  end

  def prospect_stats?
    "Cobalt" == record.name
  end

  def property_info?
    "CallCenter" == record.name
  end

  def property_schedule_availability?
    "Lineups" == record.name
  end

end
