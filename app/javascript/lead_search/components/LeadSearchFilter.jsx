import React from 'react'
import Style from './LeadSearchFilter.scss'
import FilterDropdown from './FilterDropdown.jsx'
import SearchInput from './SearchInput.jsx'

class LeadSearchFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      onUpdateSearchParams: props.onUpdateSearchParams,
      onUpdateSearchInput: props.onUpdateSearchInput,
      search: props.search,
      search_params: ""
    }
  }

  componentWillReceiveProps(new_props) {
    this.setState( { search: new_props.search })
  }

  handleSearchStringUpdate = (event) => {
    this.setState({search_params: event.target.value});
  }

  handleFilterSubmit = (event) => {
    this.state.onUpdateSearchParams(this.state.search_params);
  }

  handleUpdateSearchInput = (search_string) => {
    this.state.onUpdateSearchInput(search_string)
  }

  searchStringValue = () => {
    let value = ''
    if (this.state.search.Filters && this.state.search.Filters.Search) {
      if (this.state.search.Filters.Search.values.length > 0) {
        value = this.state.search.Filters.Search.values[0]["value"]
      }
    }
    return value
  }

  render() {
    return(
      <div className={Style.LeadSearchFilter}>
        <FilterDropdown />
        <SearchInput
          onUpdateSearchInput={this.handleUpdateSearchInput}
          value={this.searchStringValue()} />
        <div className={Style.LeadSearchParamsInput}>
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
