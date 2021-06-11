import React from 'react'
import PropTypes from 'prop-types'
import Style from './Tenacity.scss'

class Tenacity extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      data: this.props.data.data
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({data: nextProps.data.data})
  }

  recordIcon = (type) => {
    let icon_file = '';
    switch(type){
      case 'agent':
        icon_file = 'users.svg'
        break;
      case 'property':
        icon_file = 'building.svg'
        break;
      case 'team':
        icon_file = 'teams.svg'
        break;
      default:
        icon_file = 'users.svg'
    }
    return('/icons/' + icon_file)
  }

  reportRows = (type) => {
    let data = this.state.data[type]
    if (data === undefined) return(false)
    return(this.state.data[type].map(d =>
      <tr key={d.id}>
        <td><img src={this.recordIcon(type)} /></td>
        <td>{d.label}</td>
        <td>{d.value}</td>
      </tr>
      )
    )
  }


  render(){
    return(
      <div className={Style.Tenacity}>
        <h4>Tenacity</h4>
        <table className="table">
          <thead>
            <tr>
              <th></th>
              <th>Name</th>
              <th>Score</th>
            </tr>
          </thead>
          <tbody>
            {this.reportRows('team')}
            {this.reportRows('property')}
            {this.reportRows('agent')}
          </tbody>
        </table>
      </div>
    )
  }

}

Tenacity.propTypes = {
  data: PropTypes.object.isRequired
}

Tenacity.defaultProps = {
  data: { data: { properties: [], teams: [], users: []}}
}

export default Tenacity
