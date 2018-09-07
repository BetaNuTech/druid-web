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
    end
  end
end
