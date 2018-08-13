import React from 'react'
import Style from './ManagerDashboard.scss'
import axios from 'axios'
import SourcesStats from './SourcesStats.jsx'
import LeadSources from './LeadSources.jsx'
import LeadStates from './LeadStates.jsx'

class ManagerDashboard extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      api_root: '/stats',
      data: {
        lead_states: {
          data: {
            series: [ ]
          }
        },
        lead_sources: {
          data: {
            series: [ ]
          }
        }
      }
    }
  }

  componentDidMount() {
    this.updateData()
  }

  updateData = () => {
    let url = this.state.api_root + '/manager.json'
    window.activateLoader()
    axios.get(url||this.state.api)
    .then(response => {
      this.setState({ data: response.data.data })
      window.disableLoader()
    })
    .catch(error => {
      // TODO: display error to user
      //console.log(error)
    })
  }

  render() {
    return(
      <div id="ManagerDashboard" className={ Style.ManagerDashboard }>
        <LeadSources data={this.state.data.lead_sources.data}
          selectX={datum => datum.label}
          selectY={datum => datum.val}
          height='300'
          width='400'
          yAxisLabel='Leads'
        />
        <LeadStates data={this.state.data.lead_states.data}
          selectX={datum => datum.label}
          selectY={datum => datum.val}
          height='300'
          width='400'
          yAxisLabel='Leads'
        />
      </div>
    )
  }

}

export default ManagerDashboard
