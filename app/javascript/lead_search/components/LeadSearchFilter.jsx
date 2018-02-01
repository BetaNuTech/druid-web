import React from 'react'
import Style from './LeadSearchFilter.scss'
import FilterDropdown from './FilterDropdown.jsx'
import SearchInput from './SearchInput.jsx'

class LeadSearchFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      onUpdateSearchParams: props.onUpdateSearchParams,
      search_params: ""
    }
  }

  handleSearchStringUpdate = (event) => {
    this.setState({search_params: event.target.value});
  }

  handleFilterSubmit = (event) => {
    this.state.onUpdateSearchParams(this.state.search_params);
  }

  render() {
    return(
      <div className={Style.LeadSearchFilter}>
        <FilterDropdown />
        <SearchInput />
        <div className="foo">
          <input type="text" name="lead_search_manual_params" className="form-control"
            value={this.state.search_params}
            onChange={this.handleSearchStringUpdate}
          />
          <button type="submit" className="form-control btn-info" onClick={this.handleFilterSubmit}>Submit</button>
        </div>
      </div>
    )
  }
}

export default LeadSearchFilter
