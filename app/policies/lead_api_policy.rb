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

end