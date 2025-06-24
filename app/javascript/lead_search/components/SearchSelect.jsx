import React from 'react'
import Style from './SearchSelect.scss'

class SearchSelect extends React.Component {
  constructor(props) {
    super(props)
    let selected = []
    if (props.search.Filters != undefined) {
      let activeFilter = props.search.Filters[this.props.filter]
      selected = activeFilter.values
    }
    
    this.state = {
      selected: selected,
      allSelected: this.isAllOptionsSelected(selected),
      pending: false
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.search != this.props.search && this.hasFilters()) {
      this.setState({
        selected: this.activeFilter().values
      })
    }
  }

  hasFilters() {
    return(this.props.search.Filters != undefined)
  }

  activeFilter() {
    return(this.props.search.Filters[this.props.filter] )
  }

  isOptionSelected(value) {
    return(this.state.selected.find((opt) => { return( opt.value === value ) }) != undefined)
  }

  isAllOptionsSelected(selected) {

    let allOptions = this.props.search.Filters[this.props.filter].options
    return(allOptions.length != 1 && allOptions.length == selected.length)
  }

  isPending() {
    return(this.state.pending)
  }

  handleToggleSelection = (e) => {
    this.toggleSelection({ label: e.target.name, value: e.target.value })
    return false
  }

  handleToggleEntireSelection = (e) => {
    let allOptions = this.props.search.Filters[this.props.filter].options
    var newSelection
    switch(this.state.selected.length) {
      case 0:
        newSelection = allOptions
        break;
      case allOptions.length:
        newSelection = []
        break;
      default:
        newSelection = allOptions
    }
    this.commitSelection(newSelection)
  }

  handleClickApply = () => {
    this.setState({pending: false})
    this.props.onSubmitSearch(this.props.search)
    return false
  }

  toggleSelection(option) {
    let newSelection = this.state.selected
    if (this.isOptionSelected(option.value)) {
      newSelection = newSelection.filter((sel) => {
        return(sel.value != option.value)
      })
    } else {
      newSelection = [...this.state.selected, option]
    }
    this.commitSelection(newSelection)
  }

  commitSelection(selection) {
    this.setState({
      pending: true,
      allSelected: this.isAllOptionsSelected(selection),
      selected: selection
    })
    this.props.onModifyFilter()
    this.props.onUpdateFilter(this.props.filter, selection)
    return selection;
  }


  renderOptions() {
    if ( this.hasFilters() == true ) {
      return(
        this.activeFilter().options.map((opt) => {
          return(
            <div key={opt.value} className={Style.filterOption}>
              <input 
                type='checkbox' 
                id={`${this.props.filter}-${opt.value}`}
                name={opt.label} 
                value={opt.value}
                checked={this.isOptionSelected(opt.value)}
                onChange={ e => this.handleToggleSelection(e)}
              />
              <label htmlFor={`${this.props.filter}-${opt.value}`}>
                {opt.label}
              </label>
            </div>
            )
          }
        )
      )
    } else {
      return <div className={Style.noOptions}>No options available</div>
    }
  }

  render() {
    const selectedCount = this.state.selected.length
    const totalOptions = this.hasFilters() ? this.activeFilter().options.length : 0
    const isVipFilter = this.props.filter === 'VIP'
    
    return(
      <div className={`${Style.SearchSelect} ${Style.filterSection} ${isVipFilter ? Style.vipFilter : ''}`}>
        <div className={Style.filterSectionHeader}>
          <div className={Style.filterTitle}>
            <h4>
              {isVipFilter && <span className="glyphicon glyphicon-heart" aria-hidden="true"></span>}
              {this.props.filter}
            </h4>
            {selectedCount > 0 && (
              <span className={Style.selectedCount}>{selectedCount}</span>
            )}
          </div>
          <div className={Style.selectAllWrapper}>
            <label 
              className={Style.selectAllLabel}
            >
              Select All
            </label>
            <input 
              type="checkbox"
              checked={this.state.allSelected}
              onChange={ e => this.handleToggleEntireSelection(e)}
            />
          </div>
        </div>
        <div className={Style.filterSectionBody}>
          <div className={Style.filterOptions}>
            {this.renderOptions()}
          </div>
        </div>
      </div>
    )
  }
}

export default SearchSelect
