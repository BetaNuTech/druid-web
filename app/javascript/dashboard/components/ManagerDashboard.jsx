import React from 'react'
import Style from './ManagerDashboard.scss'
import axios from 'axios'
import SourcesStats from './SourcesStats.jsx'
import LeadSources from './LeadSources.jsx'
import SimpleBar from './SimpleBar.jsx'
import GroupedBar from './GroupedBar.jsx'

class ManagerDashboard extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      api_root: '/stats',
      data: {
        sources_stats: {
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
      <div className={ Style.ManagerDashboard }>
        <h1>Manager Dashboard</h1>
        <LeadSources data={this.state.data.lead_sources.data}
          selectX={datum => datum.label}
          selectY={datum => datum.val}
          height='400'
          width='500'
          yAxisLabel='Leads'
        />
      </div>
    )
  }

}

export default ManagerDashboard
