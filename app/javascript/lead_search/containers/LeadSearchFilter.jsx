import React from 'react'
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { updateSearchString, submitSearch, updateFilter, resetFilters, gotoPage, updateSortKey, updateSortDirection } from '../actions'
import Style from './LeadSearchFilter.scss'
import FilterDropdown from '../components/FilterDropdown.jsx'
import SearchInput from '../components/SearchInput.jsx'
import SearchSelect from '../components/SearchSelect.jsx'
import SearchSort from '../components/SearchSort.jsx'
import LeadSearchSidebar from '../components/LeadSearchSidebar.jsx'
import SearchDateSelect from '../components/SearchDateSelect.jsx'

class LeadSearchFilter extends React.Component {

  constructor(props) {
    super(props)
    this.state = {
      advanced: false,
      pending: false
    }
  }

  searchStringValue = () => {
    let value = ''
    if (this.props.search && this.props.search.Filters && this.props.search.Filters.Search) {
      if (this.props.search.Filters.Search.values.length > 0) {
        value = this.props.search.Filters.Search.values[0]["value"]
      }
    }
    return value
  }

  hasFilters() {
    return(this.props.search.Filters != undefined)
  }

  showAdvanced() {
    return(this.state.advanced)
  }

  isPending() {
    return(this.state.pending)
  }

  onModifyFilter = () => {
    this.setState({pending: true})
  }

  onSubmitSearch = () => {
    this.props.onSubmitSearch(this.props.search)(this.props.search)
    this.setState({pending: false})
  }

  renderSelects = () => {
    if (this.showAdvanced() && this.hasFilters()) {
      return this.props.search.Filters._index.map((filtername) => {
        const filter = this.props.search.Filters[filtername]
        if (this.hasFilters()) {
          switch(filter.type){
            case "select":
              return <SearchSelect key={filtername}
                search={this.props.search} filter={filtername}
                onModifyFilter={this.onModifyFilter}
                onUpdateFilter={this.props.onUpdateFilter(this.props.search)}
                onSubmitSearch={this.props.onSubmitSearch(this.props.search)} />
               break;
            case "date":
              return <SearchDateSelect key={filtername}
                search={this.props.search} filter={filtername}
                onModifyFilter={this.onModifyFilter}
                onUpdateFilter={this.props.onUpdateFilter(this.props.search)}
                onSubmitSearch={this.props.onSubmitSearch(this.props.search)} />
            default:
              return ""
              break;
          }
         }
      })
    }
  }

  onToggleAdvanced = () => {
    this.setState({advanced: !(this.state.advanced)})
    return false
  }

  onResetFilters = () => {
    this.props.onResetFilters(this.props.search)
    this.setState({pending: true})
    return false
  }

  render() {
    const advancedOptionsClassName = (this.state.advanced ? "btn-default" : "btn-info") + " btn btn-sm"
    return(
      <div className={Style.LeadSearchFilter}>
        <SearchInput
          onModifyFilter={this.onModifyFilter}
          onUpdateSearchInput={this.props.onUpdateSearchString(this.props.search)}
          onSubmitSearch={this.onSubmitSearch}
          value={this.searchStringValue()} />
        <SearchSort
          search={this.props.search}
          onModifyFilter={this.onModifyFilter}
          onUpdateSortDirection={this.props.onUpdateSortDirection(this.props.search)}
          onUpdateSortKey={this.props.onUpdateSortKey(this.props.search)} />
        <div className={Style.LeadSearchAdvancedFilters}>
          <button type="button" className={advancedOptionsClassName}
            onClick={this.onToggleAdvanced} >Filters</button>
          <button type="button" className="btn btn-sm btn-warning" onClick={this.onResetFilters}>Reset</button>
          { this.isPending() &&
            <button type="button" className="btn btn-sm btn-success" onClick={this.onSubmitSearch}>Submit</button>
          }
          {this.renderSelects()}
        </div>
        <LeadSearchSidebar options={this.props.search}/>
      </div>
    )
  }



}

function mapStateToProps(currentState) {
  let state = currentState
  if (state === undefined || state.search === undefined || state.search.url === undefined) {
    const endpoint =  "/leads/search.json"
    const base_url = window.location.origin + endpoint
    const search_url = base_url + window.location.search
    state = {
      search: { url: search_url, base_url: base_url }
    }
  }
  return {
    search: state.search
  }
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators({
    onUpdateSearchString: updateSearchString,
    onSubmitSearch: submitSearch,
    onUpdateFilter: updateFilter,
    onResetFilters: resetFilters,
    onUpdateSortKey: updateSortKey,
    onUpdateSortDirection: updateSortDirection
  }, dispatch)
}

export default connect(mapStateToProps, mapDispatchToProps)(LeadSearchFilter)
