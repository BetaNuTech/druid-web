import React from 'react'
import Style from './LeadActions.scss'

class LeadActions extends React.Component {

  lead_actions() {
    let actions = []
    switch(this.props.lead_state) {
      case 'open':
        actions = ['Work', 'Invalidate', 'Nurture']
        break
      case 'prospect':
        actions = ['Invalidate', 'Nurture']
        break
      case 'invalidated':
        actions = ['Validate']
        break
      case 'disqualified': // Backward compatibility for old state name
        actions = ['Validate']
        break
      default:
        actions = []
    }
    return(actions);
  }

  action_url(action) {
    const eventMapping = {
      'Work': 'work',
      'Invalidate': 'invalidate',
      'Nurture': 'nurture',
      'Validate': 'validate',
      // Legacy mappings for backward compatibility
      'Claim': 'work',
      'Disqualify': 'invalidate',
      'Abandon': 'nurture',
      'Requalify': 'validate'
    }
    const eventid = eventMapping[action] || action.toLowerCase()

    // Invalidate and Nurture need the progress_state form (require classification and/or date)
    const needsForm = ['invalidate', 'nurture'].includes(eventid)

    if (needsForm) {
      return(`/leads/${this.props.lead_id}/progress_state?eventid=${eventid}`)
    } else {
      return(`/leads/${this.props.lead_id}/trigger_state_event?eventid=${eventid}`)
    }
  }

  action_link(action) {
    const eventMapping = {
      'Work': 'work',
      'Invalidate': 'invalidate',
      'Nurture': 'nurture',
      'Validate': 'validate',
      'Claim': 'work',
      'Disqualify': 'invalidate',
      'Abandon': 'nurture',
      'Requalify': 'validate'
    }
    const eventid = eventMapping[action] || action.toLowerCase()
    const needsForm = ['invalidate', 'nurture'].includes(eventid)

    // Form actions use GET, direct triggers use POST
    if (needsForm) {
      return(
        <a href={this.action_url(action)} className="btn btn-xs btn-primary">{action}</a>
      )
    } else {
      return(
        <a href={this.action_url(action)} className="btn btn-xs btn-primary" data-remote="false" data-method="post" rel="nofollow">{action}</a>
      )
    }
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
