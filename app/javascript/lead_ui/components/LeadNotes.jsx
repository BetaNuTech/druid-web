import React from 'react'
import Style from './LeadSummary.scss'
import LeadRow from './LeadRow'

class LeadNotes extends React.Component {
  remoteid() {
    if (this.props.lead.remoteid === undefined) {
      return('')
    } else {
      return(
        <span>
          &nbsp;
          |
          &nbsp;
          <b>Remote ID</b>
          &nbsp;
            <tt>{this.props.lead.remoteid || 'n/a'}</tt>
        </span>
      )
    }
  }

  render() {
    if (this.props.lead === undefined) {
      return('')
    }
    return(
      <div className={Style.LeadNotes}>
        <LeadRow>
          <div className="col-md-12">
            <p>
              <b>Lead Comments</b><br/>
              <tt>
                {this.props.lead.preference.notes || '(none)'}
              </tt>
            </p>
            <p>
              <b>Import/Agent Note</b>
              {this.remoteid()}
              <br/>
              <tt>
                {this.props.lead.notes || '(none)'}
              </tt>
            </p>
          </div>
        </LeadRow>
      </div>
    )
  }
}

export default LeadNotes
