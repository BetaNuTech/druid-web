module Users
  module Teams
    extend ActiveSupport::Concern

    included do
      has_one :membership, class_name: 'TeamUser', dependent: :destroy
      has_one :team, through: :membership
      has_many :properties, through: :team
    end

    class_methods do
      def without_team
        User.includes(:membership).where(team_users: {id: nil})
      end

      def team_managers
        includes(:membership).where(team_users: {teamrole_id: Teamrole.manager.id})
      end

      def team_leads
        includes(:membership).where(team_users: {teamrole_id: Teamrole.lead.id})
      end

      def team_agents
        includes(:membership).where(team_users: {teamrole_id: Teamrole.agent.id})
      end

    end
  end
end
