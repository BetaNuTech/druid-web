module TeamsHelper
  def select_team(val)
    options_for_select(Team.order(name: 'ASC').map{|p| [p.name, p.id]}, val)
  end
end
