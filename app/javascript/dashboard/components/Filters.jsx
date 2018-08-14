import React from 'react'
import Style from './Filters.scss'

class Filters extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      filters: this.props.filters
    }
  }

  componentDidUpdate(prevProps) {
    this.setState({filters: this.props.filters})
  }

  propertyFiltersContent = () => {
    let property_filters = []
    if (this.state.filters.properties.length > 0) {
      property_filters = this.state.filters.properties
        .map((property) =>
          <li>{property.label}</li>
        )
    } else {
      property_filters = <li>All</li>
    }

    return(
        <div className={Style.FilterGroup}>
          <h4>Properties</h4>
          <ul>
            {property_filters}
          </ul>
        </div>
    )
  }

  userFiltersContent = () => {
    let user_filters = []

    if (this.state.filters.users.length > 0) {
      user_filters = this.state.filters.users
        .map((user) =>
          <li>{user.label}</li>
        )
    } else {
      user_filters = <li>All</li>
    }

    return(
        <div className={Style.FilterGroup}>
          <h4>Agents</h4>
          <ul>
            {user_filters}
          </ul>
        </div>
    )
  }

  render() {
    return(
      <div className={Style.Filters}>
        {this.propertyFiltersContent()}
        {this.userFiltersContent()}
      </div>
    )
  }
}

export default Filters
