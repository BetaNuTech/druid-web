import React from 'react'
import Style from './SearchInput.scss'

class SearchInput extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: props.value
    }
  }

  handleUpdateSearchInput = (event) => {
    const new_value = event.target.value
    this.setState({value: new_value})
    this.props.onUpdateSearchInput(new_value)
  }

  handleInputKeyPress = (event) => {
    if (event.key == 'Enter') {
      this.handleSubmitSearch()
    }
  }

  handleSubmitSearch = () => {
    this.props.onSubmitSearch()
  }

  componentWillReceiveProps(new_props) {
    this.setState({value: new_props.value})
  }

  render() {
    return(
      <div className={Style.SearchInput}>
        <div className={Style.searchBox}>
          <input 
            type="text" 
            className={Style.searchBox__input}
            onChange={this.handleUpdateSearchInput}
            onKeyPress={this.handleInputKeyPress}
            value={this.state.value}
            placeholder="Search leads..."
          />
          <button 
            type="button"
            className={Style.searchBox__button} 
            onClick={this.handleSubmitSearch}
            aria-label="Search"
          >
            <span className="glyphicon glyphicon-search"></span>
          </button>
        </div>
      </div>
    )
  }
}

export default SearchInput
