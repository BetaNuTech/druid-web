import React from 'react'
import { connect } from 'react-redux';

import Style from './LeadList.scss'
import LeadSearchLead from '../components/LeadSearchLead.jsx'

class LeadList extends React.Component {

  renderList() {
    if (this.props.leads == undefined) {
      window.Loader.start()
      return <h4>Please Wait...</h4>
    } else if (this.props.leads.length == 0) {
      window.Loader.stop()
      return <h3>None Found</h3>
    } else {
      window.Loader.stop()
      return this.props.leads.map( lead => {
        return <LeadSearchLead data={lead} key={lead.id}/>
      })
    }
  }

  renderCount() {
    if (this.props.meta == undefined) {
      return <span />
    } else {
      if (this.props.meta.total_count > 0) {
        if (this.props.meta.count == this.props.meta.total_count) {
          return <span className={Style.resultCount}>Displaying {this.props.meta.count} matching leads</span>
        } else {
          return <span className={Style.resultCount}>Displaying {this.props.meta.count} of {this.props.meta.total_count} matching leads</span>
        }
      } else {
        return <span />
      }
    }
  }

  render() {
    return(
      <div className={Style.LeadSearchLeads}>
        <div className={Style.ResultsTableHeader}>
          {this.renderCount()}
        </div>
        <div className={Style.ResultsTable}>
          {this.renderList()}
        </div>
      </div>
    );
  }
}

function mapStateToProps(state = {collection: []}) {
  return {
    leads: state.collection,
    meta: state.meta
  }
}

export default connect(mapStateToProps, null)(LeadList)
