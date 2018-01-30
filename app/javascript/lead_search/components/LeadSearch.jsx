import React from 'react';
import Style from './LeadSearch.scss';
import LeadSearchSidebar from './LeadSearchSidebar.jsx';
import LeadSearchFilter from './LeadSearchFilter.jsx';
import axios from 'axios';

class LeadSearch extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      api: window.location.origin + props.api,
      search: {search: {}, data: []}
    };
    this.updateSearchParams = this.updateSearchParams.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData(url) {
    axios.get(url||this.state.api)
      .then(response => {
        this.setState({ search: response.data })
      })
      .catch(error => {
        console.log(error)
      })
  }

  updateSearchParams(params) {
    this.fetchData(this.state.api + params);
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
          Leads here
        </div>
      </div>
    );
  }
}

export default LeadSearch;
