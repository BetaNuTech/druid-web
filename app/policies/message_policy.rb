# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  class IndexScope < Scope
    def resolve
      skope = scope

      # Agents see their own messages plus system user messages for their assigned or unassigned leads
      skope = if user.agent?
                system_user_id = User.system&.id
                skope.for_leads.where(leads: { property_id: user.property_ids })
                     .where('messages.user_id = ? OR (messages.user_id = ? AND (leads.user_id = ? OR leads.user_id IS NULL))',
                            user.id, system_user_id, user.id)
              # Managers, Corporate, and Admins see all messages for their properties
              elsif user.admin?
                skope.for_leads
              else
                # Managers/Corporate see all messages for their properties
                skope.for_leads.where(leads: { property_id: user.property_ids })
              end

      skope.display_order
    end
  end

  class Scope < Scope
    def resolve
      skope = scope
      skope = case user
              when lambda(&:admin?)
                skope
              else
                property_skope = skope.joins("INNER JOIN leads ON leads.id = messages.messageable_id AND messages.messageable_type = 'Lead'")
                property_skope.where(user_id: user.id).or(property_skope.where(leads: { property_id: user.property_ids }))
              end
      skope.display_order
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
      (user&.assigned_to_property?(record.messageable.property_id) ||
         user&.team_lead?(property: record.messageable.property))
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
      # Dont list messages for invalidated leads
      user.admin? || record.messageable.state != 'invalidated'
    else
      true
    end
  end

  def lead_page_mark_read?
    listable?
  end

  def allowed_params
    Message::ALLOWED_PARAMS
  end
end
