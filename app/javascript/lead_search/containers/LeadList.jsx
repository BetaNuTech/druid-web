import React from 'react'
import { connect } from 'react-redux';

import Style from './LeadList.scss'
import LeadSearchLead from '../components/LeadSearchLead.jsx'

class LeadList extends React.Component {

  renderList() {
    if (this.props.leads == undefined) {
      return <h3>Please Wait...</h3>
    } else if (this.props.leads.length == 0) {
      return <h3>None Found</h3>
    } else {
      return this.props.leads.map( lead => {
        return <LeadSearchLead data={lead} key={lead.id}/>
      })
    }
  }

  render() {
    return(
      <div className={Style.LeadSearchLeads}>
        <div className={Style.ResultsTableHeader}> </div>
        <div className={Style.ResultsTable}>
          {this.renderList()}
        </div>
      </div>
    );
  }

}

function mapStateToProps(state = {collection: []}) {
  return {
    leads: state.collection
  }
}

export default connect(mapStateToProps, null)(LeadList)
