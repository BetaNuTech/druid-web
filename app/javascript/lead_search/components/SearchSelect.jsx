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

  isPending() {
    return(this.state.pending)
  }

  handleToggleSelection = (e) => {
    this.toggleSelection({ label: e.target.name, value: e.target.value })
    return false
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
    this.setState({pending: true})
    this.props.onModifyFilter()
    this.props.onUpdateFilter(this.props.filter, newSelection)
  }

  renderOptions() {
    if ( this.hasFilters() == true ) {
      return(
        this.activeFilter().options.map((opt) => {
          return(
            <span key={opt.value} className={Style.FilterOption}>
              <label>
                <input type='checkbox' name={opt.label} value={opt.value}
                  checked={this.isOptionSelected(opt.value)}
                  onChange={ e => this.handleToggleSelection(e)}
                />
                {opt.label}
              </label>
            </span>
            )
          }
        )
      )
    } else {
      return <div>Any</div>
    }
  }

  render() {
    return(
      <div className={Style.SearchSelect}>
        <fieldset>
          <legend>{this.props.filter}</legend>
          {this.renderOptions()}
        </fieldset>
      </div>
    )
  }
}

export default SearchSelect
