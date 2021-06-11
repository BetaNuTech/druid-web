import React from 'react'
import PropTypes from 'prop-types'
import Style from './ManagerDashboard.scss'
import axios from 'axios'

import AgentStatus from './AgentStatus.jsx'
import Filters from './Filters.jsx'
import LeadSources from './LeadSources.jsx'
import LeadStates from './LeadStates.jsx'
import OpenLeads from './OpenLeads.jsx'
import PropertyLeads from './PropertyLeads.jsx'
import RecentActivity from './RecentActivity.jsx'
import SourcesStats from './SourcesStats.jsx'
import ConversionRates from './ConversionRates.jsx'
import MessageResponse  from './MessageResponse.jsx'
import LeadSpeed from './LeadSpeed.jsx'
import Tenacity from './Tenacity.jsx'

class ManagerDashboard extends React.Component {
  constructor(props) {
    super(props)
    const container = document.getElementById("Dashboard")
    this.valid_reports = [ 'lead_sources', 'lead_states', 'agent_conversion_rates', 'referral_conversion_rates', 'response_times', 'property_leads', 'open_leads', 'agent_status', 'recent_activity', 'lead_speed', 'tenacity' ]
    this.state = {
      api_root: container.dataset.api,
      initial_data: container.dataset.url,
      filters: {},
      data: { // Default empty data set
        filters: { options: { _index: [] } },
        open_leads: { data: { series: [] } },
        agent_status: { data: { series: [] } },
        lead_states: { data: { series: [ ] } },
        agent_conversion_rates: { data: { series: [ ] } },
        referral_conversion_rates: { data: { series: [ ] } },
        lead_sources: { data: { series: [ ] } },
        property_leads: { data: { series: [ ] } },
        recent_activity: { data: [] },
        response_times: { data: { series: [ ] } },
        lead_speed: { data: { properties: [], teams: [], users: []}},
        tenacity: { data: { properties: [], teams: [], users: []}},
      }
    }
  }

  componentDidMount() {
    this.updateData(this.state.initial_data)
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

  updateData = (url) => {
    window.activateLoader()
    this.valid_reports.forEach( (report_name) => {
      let report_url = url + "&report=" + report_name
      this.fetchReportData(report_url)
    })
  }

  fetchReportData = (url) => {
    axios.get(url)
    .then(response => {
      this.setState({ data: {...this.state.data, ...response.data.data}, filters: response.data.data.filters })
      window.disableLoader()
    })
    .catch(error => {
      // TODO: display error to user
      //console.log(error)
      window.disableLoader()
    })
  }

  updateFilter = (filter_name, values) => {
    const filter_data = this.state.filters
    filter_data[filter_name] = values
    this.setState({filters: filter_data})
    this.updateData(this.urlFromFilters())
    const newurl = this.urlFromFilters().replace('.json','')
    window.history.pushState("","Manager Dashboard", newurl)
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
            height={ 400 }
            width={ 700 }
            yAxisLabel='Leads'
            xAxisLabel='Lead Source'
          />
          <LeadStates data={this.state.data.lead_states.data}
            filters={this.state.data.filters}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height={ 400 }
            width={ 700 }
            yAxisLabel='Leads'
            xAxisLabel='Lead State' />
          <PropertyLeads data={this.state.data.property_leads.data}
            filters={this.state.data.filters}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height={ 400 }
            width={ 700 }
            yAxisLabel='Leads'
            xAxisLabel='Property' />
          <ConversionRates data={this.state.data.agent_conversion_rates.data}
            filters={this.state.data.filters}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height={ 400 }
            width={ 700 }
            yAxisLabel='Rate (%)'
            xAxisLabel='Agent'
            rateParameter='user_ids'
          />
          <ConversionRates data={this.state.data.referral_conversion_rates.data}
            filters={this.state.data.filters}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height={ 400 }
            width={ 700 }
            yAxisLabel='Rate (%)'
            xAxisLabel='Referral'
            rateParameter='referrals'
          />
          <MessageResponse data={this.state.data.response_times.data}
            filters={this.state.data.filters}
            selectX={datum => datum.label}
            selectY={datum => datum.val}
            height={ 400 }
            width={ 700 }
            yAxisLabel='Messages (Response in under...)'
            xAxisLabel='Agent'
          />
          <OpenLeads data={this.state.data.open_leads} />
          <AgentStatus data={this.state.data.agent_status} />
          <RecentActivity data={this.state.data.recent_activity} />
          <div className="clear"></div>
          <LeadSpeed data={this.state.data.lead_speed} />
          <Tenacity data={this.state.data.tenacity} />
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
