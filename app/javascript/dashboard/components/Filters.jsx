import React from 'react'
import PropTypes from 'prop-types'
import Style from './Filters.scss'

class FilterSection extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      options: this.props.options,
      selected: this.props.selected
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({options: nextProps.options, selected: nextProps.selected})
  }


  selectedListings = () => {
    let selectedItems = this.state.selected.map( i => {
      return(
        <li key={i.val}>
          {i.label}
          X
        </li>
      )})

    if (this.state.selected.length == 0) {
      return(<ul><li key='allitems' >All</li></ul>)
    } else {
      return( <ul>{selectedItems}</ul>)
    }
  }

  render() {
    return(
      <div key={ this.state.options.label } className={Style.FilterSection}>
        <h4>{this.state.options.label}</h4>
        <div>
          <select className="form-control">
            <option value key='defaultselect'>-- Select One --</option>
            {
              this.state.options.options.map( ( o ) => {
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
      console.log(this.state)
    return(
      <div className={Style.Filters}>
        {this.filterIndex().map( i => {
          return(
            <FilterSection
              key={i}
              options={ this.state.filters.options[i] }
              selected={ this.state.filters[i] }
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
