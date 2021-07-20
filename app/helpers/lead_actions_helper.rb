module LeadActionsHelper
  def select_action(val, state: nil)
    actions = LeadAction.for_state(state).non_system.order(name: 'asc')
    options_for_select(actions.map{|a| [a.name, a.id]},val)
  end

  def select_lead_action_state_affinity(val)
    options_for_select(LeadAction::STATE_AFFINITIES.map{|a| [a.capitalize, a]}, val)  
  end
end
