class MessagePolicy < ApplicationPolicy

  class IndexScope < Scope
    def resolve
      skope = scope
      skope = case user
        when ->(u) { u.admin? }
          if user.monitor_all_messages?
            skope.for_leads
          else
            skope.where(user_id: user.id)
          end
        else
          if user.monitor_all_messages?
            property_skope = skope.for_leads
            property_skope.where(user_id: user.id).or(property_skope.where(leads: {property_id: user.property_ids}))
          else
            skope.where(user_id: user.id)
          end
        end
      return skope.display_order
    end
  end

  class Scope < Scope
    def resolve
      skope = scope
      skope = case user
        when ->(u) { u.admin? }
          skope
        else
          property_skope = skope.joins("INNER JOIN leads ON leads.id = messages.messageable_id AND messages.messageable_type = 'Lead'")
          property_skope.where(user_id: user.id).or(property_skope.where(leads: {property_id: user.property_ids}))
        end
      return skope.display_order
    end
  end

  def index?
    user.admin? || user.user?
  end

  def new?
    user.admin? || user.user?
  end

  def create?
    new?
  end

  def show?
    is_owner? || same_property? || user.admin?
  end

  def body_preview?
    show?
  end

  def edit?
    record&.draft? &&
      (is_owner? || property_manager? || user.admin?)
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def deliver?
    edit?
  end

  def mark_read?
    user.admin? || is_owner?
  end

  def same_property?
    record&.messageable&.present? &&
      user&.properties&.include?(record.messageable.property)
  end

  def property_manager?
    record&.messageable&.property&.present? &&
      user&.property_manager?(record.messageable.property)
  end

  def listable?
    case record&.messageable
    when nil
      true
    when Lead
      # Dont list messages for disqualified leads
      user.admin? || record.messageable.state != 'disqualified'
    else
      true
    end
  end

  def allowed_params
    Message::ALLOWED_PARAMS
  end
end
