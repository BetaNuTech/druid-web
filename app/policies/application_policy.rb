class ApplicationPolicy

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end
  end


  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def is_owner?
    record.user === user
  end

  def team_lead?
    user.team_lead? &&
      user.team&.properties&.map(&:id)&.include?(record&.property_id)
  end

  def same_property?
    user&.properties.map(&:id)&.include?(record&.property_id)
  end

  def property_manager?
    record&.property&.present? && user.property_manager?(record.property)
  end
end
