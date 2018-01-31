import React from 'react';
import Style from './LeadSearchFilter.scss';

class LeadSearchFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      onUpdateSearchParams: props.onUpdateSearchParams,
      search_params: ""
    }
    this.handleSearchStringUpdate = this.handleSearchStringUpdate.bind(this);
    this.handleFilterSubmit = this.handleFilterSubmit.bind(this);
  }

  handleSearchStringUpdate(event) {
    this.setState({search_params: event.target.value});
  }

  handleFilterSubmit(event) {
    this.state.onUpdateSearchParams(this.state.search_params);
  }

  render() {
    return(
      <div className={Style.LeadSearchSidebar}>
        <h1>Filters</h1>
        <p>
          <input type="text" name="lead_search_manual_params" className="form-control"
            value={this.state.search_params}
            onChange={this.handleSearchStringUpdate}
          />
          <button type="submit" className="form-control btn-info" onClick={this.handleFilterSubmit}>Submit</button>
        </p>
      </div>
    );
  }
}

export default LeadSearchFilter;
