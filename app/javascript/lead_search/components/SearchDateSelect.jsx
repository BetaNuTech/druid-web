import React from 'react'
import Style from './SearchDateSelect.scss'

class SearchDateSelect extends React.Component {
  constructor(props) {
    super(props)
    let value = ''
    if (props.search.Filters != undefined) {
      let activeFilter = props.search.Filters[this.props.filter]
      if (activeFilter.values[0] != undefined) {
        value = activeFilter.values[0]
      }

    }
    this.state = {
      value: value,
      pending: false
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.search != this.props.search && this.hasFilters()) {
      if (this.activeFilter().values[0] != undefined) {
        this.setState({
          value: this.activeFilter().values[0]
        })
      }
    }
  }

  hasFilters() {
    return(this.props.search.Filters != undefined)
  }

  activeFilter = () => {
    return(this.props.search.Filters[this.props.filter])
  }

  handleChange = (e) => {
    const new_value = e.target.value
    this.setState({
      pending: true,
      value: new_value
    })
    this.props.onModifyFilter()
    this.props.onUpdateFilter(this.props.filter, [ new_value ])
  }

  render(){
    return(
      <div className={Style.SearchDateSelect}>
        <label>{this.props.filter}</label>
        <input 
          type="text" 
          name={this.activeFilter().param}
          className="form-control date-input" 
          value={this.state.value}
          placeholder="mm/dd/yyyy"
          onFocus={(e) => e.target.type = 'date'}
          onBlur={(e) => {
            if (!e.target.value) {
              e.target.type = 'text'
            }
          }}
          onChange={ e => this.handleChange(e)}
        />
      </div>
    )
  }
}

export default SearchDateSelect
