import React from 'react'
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { updateSearchString, submitSearch, updateFilter, resetFilters, gotoPage, updateSortKey, updateSortDirection } from '../actions'
import Style from './LeadSearchFilter.scss'
import '../components/LeadSearchFilter.scss'
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

  componentDidMount() {
    // Detect browser timezone and include it in filters
    this.ensureTimezoneInFilters()
  }

  componentDidUpdate(prevProps) {
    // Ensure timezone is set when filters change or are loaded
    if (prevProps.search !== this.props.search) {
      this.ensureTimezoneInFilters()
    }
  }

  getBrowserTimezone = () => {
    try {
      return Intl.DateTimeFormat().resolvedOptions().timeZone
    } catch (e) {
      // Fallback if Intl API is not available
      return null
    }
  }

  ensureTimezoneInFilters = () => {
    const timezone = this.getBrowserTimezone()
    if (timezone && this.props.search && this.props.search.Filters) {
      // Simply add the timezone using the existing filter mechanism
      // The filter doesn't need to be in _index to be sent as a parameter
      if (!this.props.search.Filters.timezone ||
          !this.props.search.Filters.timezone.values ||
          this.props.search.Filters.timezone.values.length === 0) {
        // Use the existing updateFilter action which works correctly
        this.props.onUpdateFilter(this.props.search)('timezone', [timezone])
      }
    }
  }

  getFriendlyTimezoneName = (timezone) => {
    if (!timezone) return ''

    // Map common IANA timezones to friendly names
    const timezoneMap = {
      'America/New_York': 'Eastern Time',
      'America/Chicago': 'Central Time',
      'America/Denver': 'Mountain Time',
      'America/Phoenix': 'Arizona Time',
      'America/Los_Angeles': 'Pacific Time',
      'America/Anchorage': 'Alaska Time',
      'Pacific/Honolulu': 'Hawaii Time',
      'America/Toronto': 'Eastern Time (Toronto)',
      'America/Vancouver': 'Pacific Time (Vancouver)',
      'Europe/London': 'British Time',
      'Europe/Paris': 'Central European Time',
      'Asia/Tokyo': 'Japan Time',
      'Australia/Sydney': 'Sydney Time',
      'UTC': 'UTC'
    }

    // Return the friendly name if available, otherwise return the last part of the timezone
    return timezoneMap[timezone] || timezone.split('/').pop().replace(/_/g, ' ')
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
    // Ensure timezone is included before submitting
    this.ensureTimezoneInFilters()
    this.props.onSubmitSearch(this.props.search)(this.props.search)
    this.setState({pending: false, advanced: false})
  }

  renderSelects = () => {
    if (this.showAdvanced() && this.hasFilters()) {
      const dateFilters = []
      const selectFilters = []
      
      this.props.search.Filters._index.forEach((filtername) => {
        const filter = this.props.search.Filters[filtername]
        if (this.hasFilters()) {
          switch(filter.type){
            case "select":
              selectFilters.push(
                <SearchSelect key={filtername}
                  search={this.props.search} filter={filtername}
                  onModifyFilter={this.onModifyFilter}
                  onUpdateFilter={this.props.onUpdateFilter(this.props.search)}
                  onSubmitSearch={this.props.onSubmitSearch(this.props.search)} />
              )
              break;
            case "date":
              dateFilters.push(
                <SearchDateSelect key={filtername}
                  search={this.props.search} filter={filtername}
                  onModifyFilter={this.onModifyFilter}
                  onUpdateFilter={this.props.onUpdateFilter(this.props.search)}
                  onSubmitSearch={this.props.onSubmitSearch(this.props.search)} />
              )
              break;
            default:
              break;
          }
        }
      })
      
      // Get the current timezone for display
      const timezone = this.getBrowserTimezone()
      const friendlyTimezone = this.getFriendlyTimezoneName(timezone)

      return (
        <div className={Style.filtersContainer}>
          {dateFilters.length > 0 && (
            <>
              <div className={Style.dateFilters}>
                {dateFilters}
              </div>
              {timezone && (
                <div className={Style.timezoneIndicator}>
                  <span className="text-muted">
                    <span className="glyphicon glyphicon-time" aria-hidden="true"></span>
                    {' '}Dates are interpreted in your browser's timezone: {friendlyTimezone}
                  </span>
                </div>
              )}
            </>
          )}
          <div className={Style.filterGrid}>
            {selectFilters}
          </div>
        </div>
      )
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
    const advancedOptionsClassName = (this.state.advanced ? "btn-primary" : "btn-secondary") + " btn"
    return(
      <div className={Style.LeadSearchFilter}>
        <div className={Style.filterHeader}>
          <div className={Style.filterTitleSection}>
            <div className={Style.filterIconWrapper}>
              <span className="glyphicon glyphicon-filter" aria-hidden="true"></span>
            </div>
            <h3>Lead Search Filters</h3>
          </div>
          <div className={Style.filterActions}>
            <button 
              type="button" 
              className={advancedOptionsClassName}
              onClick={this.onToggleAdvanced}
            >
              <span className={`glyphicon ${this.state.advanced ? 'glyphicon-eye-close' : 'glyphicon-eye-open'}`} />
              {this.state.advanced ? ' Hide Filters' : ' Show Filters'}
            </button>
            {this.state.advanced && (
              <>
                <button 
                  type="button" 
                  className="btn btn-reset" 
                  onClick={this.onResetFilters}
                >
                  <span className="glyphicon glyphicon-refresh" />
                  Reset
                </button>
                {this.isPending() && (
                  <button 
                    type="button" 
                    className="btn btn-primary" 
                    onClick={this.onSubmitSearch}
                  >
                    <span className="glyphicon glyphicon-search" />
                    Apply Filters
                  </button>
                )}
              </>
            )}
          </div>
        </div>
        
        <div className={Style.searchControls}>
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
        </div>
        
        {this.state.advanced && (
          <div className={Style.filterBody}>
            {this.renderSelects()}
          </div>
        )}
        
        <div className={Style.filterSummary}>
          <LeadSearchSidebar options={this.props.search}/>
        </div>
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
