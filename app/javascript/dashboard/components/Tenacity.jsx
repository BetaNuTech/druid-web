import React from 'react'
import PropTypes from 'prop-types'
import Style from './Tenacity.scss'

class Tenacity extends React.Component {
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
      <div className={Style.Tenacity}>
        <h4>
          Tenacity
          <button
            className={Style.infoButton}
            onClick={this.toggleInfo}
            type="button"
            aria-label="Tenacity Information"
          >
            <img src="/icons/help.svg" alt="Info" className={Style.infoIcon} />
          </button>
        </h4>

        {this.state.showInfo && (
          <div className={Style.infoBox}>
            <div className={Style.infoHeader}>
              <strong>How Tenacity Works</strong>
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
                <strong>What it measures:</strong> How persistently agents follow up with leads. Higher scores mean more consistent contact attempts.
              </p>
              <p><strong>Scoring Scale:</strong></p>
              <ul>
                <li><strong>1 touch:</strong> 3.3 score - Minimal follow-up</li>
                <li><strong>2 touches:</strong> 6.7 score - Good follow-up</li>
                <li><strong>3+ touches:</strong> 10.0 score - Excellent persistence (max score)</li>
              </ul>
              <p><strong>What counts as a "touch":</strong></p>
              <ul>
                <li>✓ Emails sent to leads (including automated welcome emails)</li>
                <li>✓ Manual text messages sent by agents</li>
                <li>✓ Completed tasks like calls, appointments, or showings</li>
                <li>✓ Notes added to contact activities</li>
              </ul>
              <p><strong>What does NOT count:</strong></p>
              <ul>
                <li>✗ Automated SMS opt-in requests and confirmations</li>
                <li>✗ Leads with no email who haven't opted in to SMS</li>
              </ul>
              <p className={Style.noteText}>
                <em>Note: The score is calculated per lead, then averaged across all leads to give the agent's overall tenacity score.</em>
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

Tenacity.propTypes = {
  data: PropTypes.object.isRequired
}

Tenacity.defaultProps = {
  data: { data: { properties: [], teams: [], users: []}}
}

export default Tenacity
