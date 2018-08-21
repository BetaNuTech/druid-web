import React from 'react'
import PropTypes from 'prop-types'
import Style from './ManagerDashboard.scss'
import axios from 'axios'
import SourcesStats from './SourcesStats.jsx'
import LeadSources from './LeadSources.jsx'
import LeadStates from './LeadStates.jsx'
import PropertyLeads from './PropertyLeads.jsx'
import OpenLeads from './OpenLeads.jsx'
import AgentStatus from './AgentStatus.jsx'
import Filters from './Filters.jsx'

class ManagerDashboard extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      api_root: '/stats/manager.json',
      filters: {},
      data: { // Default empty data set
        filters: { options: { _index: [] } },
        open_leads: { data: { series: [] } },
        agent_status: { data: { series: [] } },
        lead_states: { data: { series: [ ] } },
        lead_sources: { data: { series: [ ] } },
        property_leads: { data: { series: [ ] } }
      }
    }
  }

  componentDidMount() {
    this.updateData()
  }

  urlFromFilters = () => {
    let url = this.state.api_root + "?filter=true"
    for (var filter of this.state.data.filters.options._index) {
      for (var p of this.state.data.filters[filter]) {
        url = `${url}&${this.state.data.filters.options[filter].param}[]=${p.val}`
      }
    }
    return(url)
  }

  updateData = () => {
    window.activateLoader()
    axios.get(this.urlFromFilters())
    .then(response => {
      this.setState({ data: response.data.data, filters: response.data.data.filters })
      window.disableLoader()
    })
    .catch(error => {
      // TODO: display error to user
      //console.log(error)
      window.disableLoader()
    })
  }

  updateFilter = (filter_name, values) => {
    let filter_data = this.state.filters
    filter_data[filter_name] = values
    this.setState({filters: filter_data})
    this.updateData()
  }

  render() {
    return(
      <div className={ Style.ManagerDashboard }>
        <Filters filters={this.state.data.filters} onFilter={this.updateFilter}/>
        <div className={Style.ChartContainer} >
          <LeadSources data={this.state.data.lead_sources.data}
            filters={this.state.data.filters}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height={ 300 }
            width={ 400 }
            yAxisLabel='Leads'
            xAxisLabel='Lead Source'
          />
          <LeadStates data={this.state.data.lead_states.data}
            filters={this.state.data.filters}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height={ 300 }
            width={ 300 }
            yAxisLabel='Leads'
            xAxisLabel='Lead State' />
          <PropertyLeads data={this.state.data.property_leads.data}
            filters={this.state.data.filters}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height={ 300 }
            width={ 700 }
            yAxisLabel='Leads'
            xAxisLabel='Property' />
          <OpenLeads data={this.state.data.open_leads} />
          <AgentStatus data={this.state.data.agent_status} />
        </div>
      </div>
    )
  }

}

ManagerDashboard.propTypes = {
  data: PropTypes.object,
  api_root: PropTypes.string
}

export default ManagerDashboard
