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
          <ul className="FilterList dropdown-menu">
            <li><a href="#">My Leads</a></li>
            <li><a href="#">Open Leads</a></li>
            <li><a href="#">Closed Leads</a></li>
            <li role="separator" className="divider"></li>
            <li><a href="#">Filter4</a></li>
          </ul>
        </div>
      </div>
    )
  }
}

export default FilterDropdown
