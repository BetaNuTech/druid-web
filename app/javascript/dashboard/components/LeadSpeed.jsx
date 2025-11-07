import React from 'react'
import PropTypes from 'prop-types'
import Style from './LeadSpeed.scss'

class LeadSpeed extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      data: this.props.data.data,
      showInfo: false
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({data: nextProps.data.data})
  }

  toggleInfo = () => {
    this.setState({ showInfo: !this.state.showInfo })
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
      <div className={Style.LeadSpeed}>
        <h4>
          Lead Speed
          <button
            className={Style.infoButton}
            onClick={this.toggleInfo}
            type="button"
            aria-label="Lead Speed Information"
          >
            <img src="/icons/help.svg" alt="Info" className={Style.infoIcon} />
          </button>
        </h4>

        {this.state.showInfo && (
          <div className={Style.infoBox}>
            <div className={Style.infoHeader}>
              <strong>How Lead Speed Works</strong>
              <button
                className={Style.closeButton}
                onClick={this.toggleInfo}
                type="button"
                aria-label="Close"
              >
                ×
              </button>
            </div>
            <div className={Style.infoContent}>
              <p>
                <strong>Timer starts:</strong> From when the lead is created (not when claimed or moved to prospect state).
              </p>
              <p>
                <strong>Business Hours Only:</strong> The timer only counts time during each property's configured office hours.
                Time outside of business hours (nights, weekends, holidays, and closed days) is not counted.
                If a lead comes in after hours, the timer starts when the office next opens.
              </p>
              <p><strong>Grading Scale:</strong></p>
              <ul>
                <li><strong>Grade A:</strong> 0-29 minutes (business hours) - Excellent response time</li>
                <li><strong>Grade B:</strong> 30-120 minutes (business hours) - Good response time</li>
                <li><strong>Grade C:</strong> 120+ minutes (business hours) - Needs improvement</li>
              </ul>
              <p className={Style.noteText}>
                <em>Note: Phone-sourced leads get automatic first contact at creation (0 minutes) since the lead calling in is the first contact.</em>
              </p>
            </div>
          </div>
        )}

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

LeadSpeed.propTypes = {
  data: PropTypes.object.isRequired
}

LeadSpeed.defaultProps = {
  data: { data: { properties: [], teams: [], users: []}}
}

export default LeadSpeed
