module Users
  module Teams
    extend ActiveSupport::Concern

    included do
      has_one :membership, class_name: 'TeamUser', dependent: :destroy
      has_one :teamrole, through: :membership
      has_one :team, through: :membership

      def team_title
        membership&.teamrole&.name
      end

      def team_admin?
        team_lead? || team_corporate?
      end

      def team_corporate?
        teamrole&.lead? || false
      end

      def team_manager?
        raise "Manager Teamrole is deprecated"
        # teamrole.try(:manager?) || false
      end

      def team_lead?(property: nil)
        if property
          team_lead? && membership.team.property_ids.include?(property.id)
        else
          teamrole&.lead?
        end
      end

      def team_agent?
        teamrole&.agent?
      end
    end

    class_methods do

      def with_team
        includes(:membership).where("team_users.id IS NOT null")
      end

      def without_team
        includes(:membership).where(team_users: {id: nil})
      end

      def team_managers
        raise "Manager Teamrole is deprecated"
        # includes(:membership).where(team_users: {teamrole_id: Teamrole.manager&.id})
      end

      def team_leads
        includes(:membership).where(team_users: {teamrole_id: Teamrole.lead&.id})
      end

      def team_agents
        includes(:membership).where(team_users: {teamrole_id: Teamrole.agent&.id})
      end

    end
  end
end
