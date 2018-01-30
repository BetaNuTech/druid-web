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
  }

  handleSearchStringUpdate(event) {
    this.setState({search_params: event.target.value});
    this.state.onUpdateSearchParams(this.state.search_params);
  }

  render() {
    return(
      <div className={Style.LeadSearchSidebar}>
        Filters
        <p>
          <input type="text" name="search_params" className="form-control"
            value={this.state.search_params}
            onChange={this.handleSearchStringUpdate} />
        </p>
      </div>
    );
  }
}

export default LeadSearchFilter;
