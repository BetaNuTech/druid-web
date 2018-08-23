import React from 'react'
import PropTypes from 'prop-types'
import Style from './Filters.scss'

class FilterSection extends React.Component {

  selectedListings = () => {
    let selectedItems = this.props.selected.map( i => {
      return(
        <li key={i.val}>
          {i.label} &nbsp;
          <a href="#" className={Style.RemoveFilter} data-value={i.val} onClick={this.removeSelectedFilter}>x</a>
        </li>
      )})

    if (this.props.selected.length == 0) {
      return(<ul className="FilterListing"><li key='allitems' >All</li></ul>)
    } else {
      return( <ul className="FilterListing">{selectedItems}</ul>)
    }
  }

  filterSelected = (e) => {
    const selectedItem = this.props.options.options[e.target.selectedIndex - 1]
    const isValidSelection = ( selectedItem != undefined ) && (!this.isSelected(selectedItem.val))
    if (isValidSelection) {
      const newSelected = [...this.props.selected, selectedItem]
      this.props.onFilter(this.props.filterKey, newSelected)
    }
    e.target.selectedIndex = 0
  }

  removeSelectedFilter = (e) => {
    e.preventDefault()
    const filterId = e.target.dataset.value
    if (this.isSelected(filterId)) {
      const newSelected = this.props.selected.filter( s => s.val != filterId)
      this.props.onFilter(this.props.filterKey, newSelected)
    }
  }

  isSelected = (id) => {
    return(this.props.selected.map( d => d.val).indexOf(id) != -1)
  }

  optionElement = (o) => {
    if (this.isSelected(o.val)) {
      return(<option key={o.val} value={o.val} disabled>{o.label}</option>)
    } else {
      return(<option key={o.val} value={o.val}>{o.label}</option>)
    }
  }

  render() {
    return(
      <div key={ this.props.options.label } className={Style.FilterSection}>
        <h4>{this.props.options.label}</h4>
        <div>
          <select className="form-control" onChange={this.filterSelected}>
            <option value key='defaultselect'>-- Select {this.props.options.label} --</option>
            {
              this.props.options.options.map( ( o ) => {
                return(this.optionElement(o))
              })
            }
          </select>
        </div>
        {this.selectedListings()}
      </div>
    )
  }
}

class Filters extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      filters: this.props.filters
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({filters: nextProps.filters})
  }

  filterIndex = () => {
    return(this.state.filters.options == undefined ? [] : this.state.filters.options._index)
  }

  render() {
    return(
      <div className={Style.Filters}>
        {this.filterIndex().map( i => {
          return(
            <FilterSection
              key={i}
              filterKey={i}
              options={ this.state.filters.options[i] }
              selected={ this.state.filters[i] }
              onFilter={this.props.onFilter}
            />)
        })}
      </div>
    )
  }
}

Filters.propTypes = {
  filters: PropTypes.object
}

Filters.defaultProps = {
  filters: {
    options: {
      _index: []
    }
  }
}

export default Filters
