import React from 'react'
import Style from './SearchSort.scss'

class SearchSort extends React.Component {
  constructor(props) {
    super(props)
    let selectedKey = []
    let selectedDirection = []
    if (props.search.Pagination != undefined) {
      selectedKey = props.search.Pagination.SortBy.values
      selectedKey = props.search.Pagination.SortDir.values
    }
    this.state = {
      selectedKey: selectedKey,
      selectedDirection: selectedDirection
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.search != this.props.search && this.hasPagination()) {
      this.setState({
        selectedKey: this.props.search.Pagination.SortBy.values,
        selectedDirection: this.props.search.Pagination.SortDir.values,
      })
    }
  }

  hasPagination() {
    return(this.props.search.Pagination != undefined)
  }

  isKeySelected(value) {
    return(this.state.selectedKey.find((opt) => { return( opt.value === value ) }) != undefined)
  }

  isDirectionSelected(value) {
    return(this.state.selectedDirection.find((opt) => { return( opt.value === value ) }) != undefined)
  }

  selectedDirection() {
    if (this.hasPagination()) {
      if (this.state.selectedDirection[0] != undefined) {
        return(this.state.selectedDirection[0].value)
      } else {
        return('')
      }
    } else {
      return('')
    }
  }

  selectedKey() {
    if (this.hasPagination()) {
      if (this.state.selectedKey[0] != undefined) {
        return(this.state.selectedKey[0].value)
      } else {
        return('')
      }
    } else {
      return('')
    }
  }


  renderKeySelect = () => {
    if (this.hasPagination()) {
      return(
        <select className="form-control" value={this.selectedKey()}
            onChange={this.handleSelectKey} >
          {this.props.search.Pagination.SortBy.options.map((key) => {
            return <option key={key.value} value={key.value}>{key.label}</option>
          })}
        </select>
      )
    } else {
      return(<select className="form-control" />)
    }
  }

  renderDirectionSelect = () => {
    if (this.hasPagination()) {
      return(
        <select className="form-control" value={this.selectedDirection()}
            onChange={this.handleSelectDirection} >
          {this.props.search.Pagination.SortDir.options.map((key) => {
            return <option key={key.value} value={key.value}>{key.label}</option>
          })}
        </select>
      )
    } else {
      return(<select className="form-control" />)
    }
  }

  handleSelectKey = (e) => {
    const value = e.target.value
    this.selectKey(value)
  }

  selectKey(option) {
    this.props.onUpdateSortKey(option)
  }

  handleSelectDirection = (e) => {
    const value = e.target.value
    this.selectDirection(value)
  }

  selectDirection(option) {
    this.props.onUpdateSortDirection(option)
  }

  render(){
    return(
      <div className={Style.SearchSort}>
        <span className={Style.SearchSort.selector}>
          <label>Sort By</label>{this.renderKeySelect()}
        </span>
        <span className={Style.SearchSort.selector}>
          <label>Direction</label>{this.renderDirectionSelect()}
        </span>
      </div>
    )
  }

}

export default SearchSort
