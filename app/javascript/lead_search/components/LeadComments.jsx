import React from 'react'
import Style from './LeadComments.scss'

class LeadComments extends React.Component {

  render() {
    return(
      <div className={Style.LeadComments}>
        <p>
          Add Comment
        </p>
        <p>
          Lead Comments Here
        </p>
      </div>
    )
  }
}

export default LeadComments
