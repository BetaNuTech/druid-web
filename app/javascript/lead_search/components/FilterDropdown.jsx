import React from 'react'
import Style from './FilterDropdown.scss'

class FilterDropdown extends React.Component {
  render() {
    return (
      <div className={Style.FilterDropdown} >
        <div className="btn-group btn-default">
          <button type="button" className="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            Filter <span className="caret"></span>
          </button>
          <ul className="dropdown-menu">
            <li><a href="#">Filter1</a></li>
            <li><a href="#">Filter2</a></li>
            <li><a href="#">Filter3</a></li>
            <li role="separator" className="divider"></li>
            <li><a href="#">Filter4</a></li>
          </ul>
        </div>
      </div>
    )
  }
}

export default FilterDropdown
