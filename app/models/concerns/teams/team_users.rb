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
        memberships.where(user_id: user.id).first&.teamrole
      end

      def managers
        raise "Team Manager Role is Deprecated"
        members.team_managers.order("team_users.created_at ASC")
      end

      def teamleads
        members.team_leads.order("team_users.created_at ASC")
      end

      def agents
        members.team_agents.order("team_users.created_at ASC")
      end

    end
  end
end
