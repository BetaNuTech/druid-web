import React from 'react';
import Style from './LeadSearch.scss';
import LeadSearchSidebar from './LeadSearchSidebar.jsx';
import LeadSearchFilter from './LeadSearchFilter.jsx';
import LeadSearchLeads from './LeadSearchLeads.jsx';
import axios from 'axios';

class LeadSearch extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      api: window.location.origin + props.api,
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

  handleUpdateSearchParams = (params) => {
    this.fetchData(this.state.api + params)
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
            onUpdateSearchParams={this.handleUpdateSearchParams}
            onUpdateSearchInput={this.handleUpdateSearchInput}
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
