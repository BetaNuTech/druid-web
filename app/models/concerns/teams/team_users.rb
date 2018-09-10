module Teams
  module TeamUsers
    extend ActiveSupport::Concern

    included do
      has_many :memberships, class_name: 'TeamUser', dependent: :destroy
      has_many :members, through: :memberships, source: :user, class_name: 'User'

      accepts_nested_attributes_for :memberships, allow_destroy: true,
        reject_if: ->(attrs){ attrs['user_id'].blank? }

      def member?(user)
        return members.where(id: user.id).exists?
      end

      def teamrole_for(user)
        memberships.where(user_id: user.id).first.teamrole
      end

      def managers
        members.team_managers.order("created_at ASC")
      end

      def leads
        members.team_leads.order("created_at ASC")
      end

      def agents
        memberships.where(teamrole_id: Teamrole.lead.id).
          order("created_at ASC").first.try(:user)
      end

    end
  end
end
