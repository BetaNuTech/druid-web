class RoommatePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      skope = scope
      return case user
        when ->(u) { u.administrator? }
          skope
        when ->(u) { u.corporate? }
          skope
        when -> (u) { u.team_lead?}
          skope.
            includes(lead: :property).
            for_team(user.team).
            where(properties: {active: [ true, nil ]})
        else
          # Belonging to User
          skope.includes(lead: :property).
            where(leads: {user_id: user.id}).
            or(skope.includes(lead: :property).
               where(leads: { property_id: user.properties.pluck(:id)}))
        end
    end
  end

  #def index?
    #user.admin? || ( user.user? && same_property? )
  #end

  #def show?
    #user.admin? || ( user.user? && same_property? )
  #end

  def new?
    user.admin? || user.user?
  end

  def create?
    new?
  end

  def edit?
    user.admin? || ( user.user? || same_property? )
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def allowed_params
    return Roommate::ALLOWED_PARAMS
  end

  def same_property?
    user.properties.pluck(:id).include?(record&.lead&.property_id)
  end

end
