import React from 'react'
import Style from './SearchInput.scss'

class SearchInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: props.value,
      onUpdateSearchInput: props.onUpdateSearchInput,
      onSubmitSearch: props.onSubmitSearch
    }
  }

  handleUpdateSearchInput = (event) => {
    const new_value = event.target.value
    this.setState({value: new_value})
    this.state.onUpdateSearchInput(new_value)
  }

  handleInputKeyPress = (event) => {
    if (event.key == 'Enter') {
      this.handleSubmitSearch()
    }
  }

  handleSubmitSearch = () => {
    this.state.onSubmitSearch()
  }

  componentWillReceiveProps(new_props) {
    this.setState({value: new_props.value})
  }

  render() {
    return(
      <div className={Style.SearchInput}>
        <div className="input-group">
          <input type="text" className="form-control"
            onChange={this.handleUpdateSearchInput}
            onKeyPress={this.handleInputKeyPress}
            value={this.state.value}
          />
          <span className="input-group-addon" onClick={this.handleSubmitSearch}>
            <span className="glyphicon glyphicon-search"></span>
          </span>
        </div>
      </div>
    )
  }
}

export default SearchInput
