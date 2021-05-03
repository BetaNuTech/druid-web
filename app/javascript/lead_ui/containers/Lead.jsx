import axios from 'axios'
import React from 'react'
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { initialFetchLead, fetchLead } from '../actions'

import Style from './Lead.scss'
import LeadSummary from '../components/LeadSummary'
import LeadNotes from '../components/LeadNotes'
import Roommates from '../components/Roommates'
import LeadTasks from '../components/LeadTasks'

class Lead extends React.Component {
  componentDidMount() {
    this.props.initialFetchLead({url: this.props.api_url})
    console.log('Lead component mounted')
  }

  loadingUI() {
    return(
      <span>Loading Lead...</span>
    )
  }

  render() {
    return (
      this.props.lead === undefined ?
        this.loadingUI()
        :
        <div className={Style.Lead}>
          <LeadSummary lead={this.props.lead} lead_id={this.props.lead_id}/>
          <LeadNotes lead={this.props.lead }/>
          <Roommates lead={this.props.lead }/>
          <LeadTasks lead={this.props.lead }/>
        </div>
    )
  }
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators({
    initialFetchLead: initialFetchLead,
    fetchLead: fetchLead
  }, dispatch)
}

function mapStateToProps(state, ownProps) {
  if (state === undefined) {
    return {
      loading: ownProps.loading,
      lead_id: ownProps.lead_id,
      lead: ownProps.lead,
      api_url: ownProps.api_url,
      meta: ownProps.meta,
      updated: ownProps.updated
    }

  } else {
    return {
      loading: state.loading,
      lead_id: state.lead_id,
      lead: state.lead,
      api_url: state.api_url,
      meta: state.meta,
      updated: state.updated
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Lead)
