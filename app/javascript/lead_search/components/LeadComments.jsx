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
    if (!this.props.comments || this.props.comments.length === 0) {
      return null;
    }
    
    return(
      <div className={Style.LeadComments}>
        <p>
          <strong>Agent Comments: </strong>
          { this.comment_list() }
        </p>  
      </div>
    )
  }
}

export default LeadComments
