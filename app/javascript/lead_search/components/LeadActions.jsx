import React from 'react'
import Style from './LeadActions.scss'

class LeadActions extends React.Component {

   render() {
     return(
      <div className={Style.LeadActions}>
        (TODO: Lead Actions For {this.props.lead_id} )<br/>
        Claim - Change State - Edit
      </div>
     )
   }

}

export default LeadActions
