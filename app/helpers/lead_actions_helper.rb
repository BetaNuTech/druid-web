module LeadActionsHelper
  def select_action(val)
    options_for_select(LeadAction.order(name: 'ASC').map{|a| [a.name, a.id]},val)
  end
end
