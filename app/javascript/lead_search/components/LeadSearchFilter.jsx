import React from 'react'
import Style from './LeadSearchFilter.scss'
import FilterDropdown from './FilterDropdown.jsx'
import SearchInput from './SearchInput.jsx'

class LeadSearchFilter extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      onUpdateSearchInput: props.onUpdateSearchInput,
      onSubmitSearch: props.onSubmitSearch,
      search: props.search
    }
  }

  componentWillReceiveProps(new_props) {
    this.setState( { search: new_props.search })
  }

  handleSearchStringUpdate = (event) => {
    this.setState({search_params: event.target.value});
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
        { false && <FilterDropdown /> }
        <SearchInput
          onUpdateSearchInput={this.handleUpdateSearchInput}
          onSubmitSearch={this.state.onSubmitSearch}
          value={this.searchStringValue()} />
      </div>
    )
  }
}

export default LeadSearchFilter
