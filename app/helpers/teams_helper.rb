module TeamsHelper
  def select_team(val)
    options_for_select(Team.order(name: 'ASC').map{|p| [p.name, p.id]}, val)
  end

  def team_membership_user_select(val)
    options_for_select(User.without_team.map{|user| [user.name, user.id]}, val)
  end

  def team_membership_teamrole_select(val)
    options_for_select(Teamrole.order(name: 'ASC').map{|r| [r.name, r.id]}, val)
  end
end
