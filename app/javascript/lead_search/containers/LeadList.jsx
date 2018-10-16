import React from 'react'
import { connect } from 'react-redux';

import Style from './LeadList.scss'
import LeadSearchLead from '../components/LeadSearchLead.jsx'

class LeadList extends React.Component {

  renderList() {
    if (this.props.leads != undefined && this.props.leads.length > 0) {
      return this.props.leads.map( lead => {
        return <LeadSearchLead data={lead} key={lead.id}/>
      })
    } else {
      return <h3>None Found</h3>
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
