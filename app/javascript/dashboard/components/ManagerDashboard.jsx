import React from 'react'
import Style from './ManagerDashboard.scss'
import axios from 'axios'
import SourcesStats from './SourcesStats.jsx'
import LeadSources from './LeadSources.jsx'
import LeadStates from './LeadStates.jsx'
import PropertyLeads from './PropertyLeads.jsx'
import Filters from './Filters.jsx'

class ManagerDashboard extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      api_root: '/stats/manager.json',
      data: {
        filters: {
          properties: [],
          users: []
        },
        lead_states: {
          data: {
            series: [ ]
          }
        },
        lead_sources: {
          data: {
            series: [ ]
          }
        },
        property_leads: {
          data: {
            series: [ ]
          }
        }
      }
    }
  }


  getInitialUrl() {
    return( this.state.api_root + window.location.search )
  }

  urlFromFilters = () => {
    let url = this.state.api_root + "?filter=true"

    let property_id_params = this.state.data.filters.properties.map(d => `property_id[]=${d}`)
    let user_id_params = this.state.data.filters.users.map(d => `user_id[]=${d}`)


    for (var p of this.state.data.filters.properties) {
      url = `${url}&property_id[]=${p.val}`
    }

    for (var p of this.state.data.filters.users) {
      url = `${url}&user_id[]=${p.val}`
    }

    return(url)
  }

  componentDidMount() {
    this.updateData()
  }

  updateData = () => {
    window.activateLoader()
    axios.get(this.getInitialUrl()||this.state.api)
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
        <Filters filters={this.state.data.filters}/>
        <div className={Style.ChartContainer} >
          <LeadSources data={this.state.data.lead_sources.data}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height='300'
            width='400'
            yAxisLabel='Leads'
            xAxisLabel='Lead Source'
          />
          <LeadStates data={this.state.data.lead_states.data}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height='300'
            width='400'
            yAxisLabel='Leads'
            xAxisLabel='Lead State'
          />
          <PropertyLeads data={this.state.data.property_leads.data}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height='300'
            width='700'
            yAxisLabel='Leads'
            xAxisLabel='Property'
          />
        </div>
      </div>
    )
  }

}

export default ManagerDashboard
