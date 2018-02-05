import React from 'react'
import Style from './LeadSearch.scss'
import LeadSearchSidebar from './LeadSearchSidebar.jsx'
import LeadSearchFilter from './LeadSearchFilter.jsx'
import LeadSearchLeads from './LeadSearchLeads.jsx'
import Pagination from './Pagination.jsx'
import axios from 'axios'

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

  getInitialUrl() {
    return( this.state.api + window.location.search )
  }

  componentDidMount() {
    this.fetchData(this.getInitialUrl())
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

  handleGotoPage = (page) => {
    let newSearchState = {
      ...this.state.search,
      search: {
        ...this.state.search.search,
        Pagination: {
          ...this.state.search.search.Pagination,
          Page: {
            ...this.state.search.search.Pagination.Page,
            values: [{label: "Page", value: page}]
          }
        }
      }
    }
    this.setState({search: newSearchState}, this.handleSubmitSearch)
    window.scrollTo(0,0)
  }

  urlParamsFromSearch() {
    let filterParams = this.paramsFromSearchNode(this.state.search.search.Filters)
    let paginationParams = this.paramsFromSearchNode(this.state.search.search.Pagination)
    let output = "?" + [...filterParams, ...paginationParams].join("&")
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
          <h1>Lead Search</h1>
          <a name="top"></a>
        </div>
        <LeadSearchFilter
          search={this.state.search.search}
          onUpdateSearchInput={this.handleUpdateSearchInput}
          onSubmitSearch={this.handleSubmitSearch}
        />
        <LeadSearchSidebar options={this.state.search.search}/>
        <LeadSearchLeads data={this.state.search.data}/>
        <Pagination search={this.state.search.search} onGotoPage={this.handleGotoPage}/>
      </div>
    );
  }
}

export default LeadSearch
