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

  updateSearchParams = (params) => {
    this.fetchData(this.state.api + params)
  }

  render() {
    return (
      <div className={Style.LeadSearch}>
        <div className={Style.header}>
          <h1>Lead Search (React.js)</h1>
          <strong>API:</strong> {this.state.api}
        </div>
        <div className={Style.filter}>
          <LeadSearchFilter onUpdateSearchParams={this.updateSearchParams}/>
        </div>
        <div className={Style.sidebar}>
          <LeadSearchSidebar options={this.state.search.search}/>
        </div>
        <div className={Style.leads}>
          <LeadSearchLeads data={this.state.search.data}/>
        </div>
      </div>
    );
  }
}

export default LeadSearch
