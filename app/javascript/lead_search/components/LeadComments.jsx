import React from 'react'
import Style from './LeadComments.scss'

class LeadComments extends React.Component {

  comment_list(){
    return(this.props.comments.map((comment) =>
      <span key={comment.id}>
        {comment.status_line_short} 
        <br/>
      </span>
    ));
  }

  render() {
    return(
      <div className={Style.LeadComments}>
        <p>
          <strong>Agent Comments: </strong><br/>
          { this.comment_list() }
        </p>  
      </div>
    )
  }
}

export default LeadComments
