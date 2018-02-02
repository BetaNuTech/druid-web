import React from 'react';
import Style from './LeadSearch.scss';
import LeadSearchSidebar from './LeadSearchSidebar.jsx';
import LeadSearchFilter from './LeadSearchFilter.jsx';
import LeadSearchLeads from './LeadSearchLeads.jsx';
import axios from 'axios';

class LeadSearch extends React.Component {
  constructor(props) {
    super(props)
    let api = props.api
    if (!RegExp('^http').test(api)) { api = window.location.origin + api  }
    axios.defaults.baseURL = api
    this.state = {
      api: api,
      search: {search: {}, data: []}
    }
  }

  componentDidMount() {
    this.fetchData()
  }

  fetchData(url) {
    axios.get(url||this.state.api)
      .then(response => {
        this.setState({ search: response.data })
      })
      .catch(error => {
        // TODO: display error to user
        console.log(error)
      })
  }

  handleUpdateSearchInput = (search_string) => {
    let newSearchState = {
      ...this.state.search,
      search: {
        ...this.state.search.search,
        Filters: {
          ...this.state.search.search.Filters,
          Search: {
            ...this.state.search.search.Filters.Search,
            values: [{label: search_string, value: search_string}]
          }
        }
      }
    }
    this.setState({search: newSearchState})
  }

  handleSubmitSearch = () => {
    this.fetchData(this.urlParamsFromSearch())
  }

  urlParamsFromSearch() {
    let output = ''
    let params = []
    let filterParams = this.paramsFromSearchNode(this.state.search.search.Filters)
    let paginationParams = this.paramsFromSearchNode(this.state.search.search.Pagination)
    output = "?" + [...filterParams, ...paginationParams].join("&")
    return output
  }

  paramsFromSearchNode(segment) {
    const search_param = this.props.search_param
    let params = []
    segment._index.forEach(function(key) {
        let param = segment[key]["param"]
        segment[key]["values"].forEach(function(val) {
          let value = val["value"]
          if (value.length > 0) {
            let safeVal = encodeURIComponent(value)
            params.push(`${search_param}[${param}][]=${safeVal}`)
          }
        })
      })
    return params
  }

  render() {
    return (
      <div className={Style.LeadSearch}>
        <div className={Style.header}>
          <h1>Lead Search (React.js)</h1>
          <strong>API:</strong> {this.state.api}
        </div>
        <div className={Style.LeadSearchFilter}>
          <LeadSearchFilter
            search={this.state.search.search}
            onUpdateSearchInput={this.handleUpdateSearchInput}
            onSubmitSearch={this.handleSubmitSearch}
          />
        </div>
        <div className={Style.LeadSearchSidebar}>
          <LeadSearchSidebar options={this.state.search.search}/>
        </div>
        <div className={Style.LeadSearchLeads}>
          <LeadSearchLeads data={this.state.search.data}/>
        </div>
      </div>
    );
  }
}

export default LeadSearch
