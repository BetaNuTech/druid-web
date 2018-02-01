import React from 'react'
import Style from './SearchInput.scss'

class SearchInput extends React.Component {
  render() {
    return(
      <div className={Style.SearchInput}>
        <input type="text" className="form-control"/>
      </div>
    )
  }
}

export default SearchInput
