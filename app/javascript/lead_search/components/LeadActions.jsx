import React from 'react'
import Style from './LeadActions.scss'

class LeadActions extends React.Component {

  lead_actions() {
    let actions = []
    switch(this.props.lead_state) {
      case 'open':
        actions = ['Claim', 'Disqualify']
        break
      case 'prospect':
        actions = ['Disqualify']
        break
      case 'disqualified':
        actions = ['Requalify']
      default:
        actions = ['Disqualify']
    }
    return(actions);
  }

  action_url(action) {
    return(`/leads/${this.props.lead_id}/trigger_state_event?eventid=${action}`)
  }

  action_link(action) {
    const actionid = action.toLowerCase()
    let data_remote = 'false'
    let data_target = '_blank'

    return(
      <a href={this.action_url(action.toLowerCase())} className="btn btn-xs btn-primary" data-remote='false' data-method="post" rel="nofollow" target='_blank'>{action}</a>
    )
  }

  action_buttons() {
    return(this.lead_actions().map((action) =>
      <span key={`${this.props.lead_id}-action-${action}`}>
        { this.action_link(action) }
        &nbsp;
      </span>
    ))
  }

   render() {
     return(
      <span className={Style.LeadActions}>
        &nbsp;
        { this.action_buttons() }
      </span>
     )
   }

}

export default LeadActions
