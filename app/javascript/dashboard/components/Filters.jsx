import React from 'react'
import PropTypes from 'prop-types'
import Style from './Filters.scss'

class FilterSection extends React.Component {

  selectedListings = () => {
    let selectedItems = this.props.selected.map( i => {
      return(
        <li key={i.val}>
          {i.label} &nbsp;
          X
        </li>
      )})

    if (this.props.selected.length == 0) {
      return(<ul><li key='allitems' >All</li></ul>)
    } else {
      return( <ul>{selectedItems}</ul>)
    }
  }

  filterSelected = (e) => {
    let selectedItem = this.props.options.options[e.target.selectedIndex - 1]
    let isValidSelection = ( selectedItem != undefined ) && ( this.props.selected.indexOf(selectedItem) == -1 )
    if (isValidSelection) {
      let newSelected = [...this.props.selected, selectedItem]
      this.props.onFilter(this.props.filterKey, newSelected)
    }
  }

  render() {
    return(
      <div key={ this.props.options.label } className={Style.FilterSection}>
        <h4>{this.props.options.label}</h4>
        <div>
          <select className="form-control" onChange={this.filterSelected} data-filter={this.props.filterKey}>
            <option value key='defaultselect'>-- Select One --</option>
            {
              this.props.options.options.map( ( o ) => {
                return(<option key={o.val} value={o.val}>{o.label}</option>)
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
