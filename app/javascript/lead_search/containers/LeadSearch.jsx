import React from 'react'
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { initialFetchLeads, fetchLeads, gotoPage } from '../actions'
import Style from './LeadSearch.scss'
import LeadSearchSidebar from '../components/LeadSearchSidebar.jsx'
import LeadSearchFilter from '../containers/LeadSearchFilter.jsx'
import LeadList from './LeadList.jsx'
import Pagination from '../components/Pagination.jsx'
import axios from 'axios'

class LeadSearch extends React.Component {

  componentDidMount() {
    this.props.initialFetchLeads(this.props.search)
  }

  csvUrl() {
    if (this.props.search != undefined && this.props.search.url != undefined) {
      return(this.props.search.url.replace(/.json/,'.csv'))
    } else {
      return('#')
    }
  }

  csvDownloadLink() {
    let link_div = ''
    if (this.props.collection != undefined && this.props.collection.length > 0) {
      return(<div><a className="btn btn-xs btn-info" href={this.csvUrl()} target="_blank" rel="alternate">Download CSV</a></div>)
    } else {
      return(<div/>)
    }
  }

  render() {
    return (
      <div className={Style.LeadSearch}>
        <div className={Style.Header}>
          <h1>Search Leads</h1>
        </div>
        <LeadSearchFilter search={this.props.search} />
        <LeadList leads={this.props.collection} meta={this.props.meta} />
        <Pagination search={this.props.search} onSelect={this.props.gotoPage(this.props.search)} />
        {this.csvDownloadLink()}
      </div>
    )
  }
}

function mapStateToProps(currentState) {
  let state = currentState
  if (state === undefined || state.search.url === undefined) {
    const endpoint =  "/leads/search.json"
    const base_url = window.location.origin + endpoint
    const search_url = base_url + window.location.search
    state = {
      loading: false,
      collection: [],
      meta: { version: '0', count: 0, total_count: 0},
      search: { url: search_url, base_url: base_url }
    }
  }
  return {
    loading: state.loading,
    search: state.search,
    collection: state.collection,
    meta: state.meta
  }
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators({
    initialFetchLeads: initialFetchLeads,
    fetchLeads: fetchLeads,
    gotoPage: gotoPage
  },
  dispatch)
}

export default connect(mapStateToProps, mapDispatchToProps)(LeadSearch)
