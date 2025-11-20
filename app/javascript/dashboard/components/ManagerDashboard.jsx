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
      browserTimezone: null, // Store browser timezone
      customStartDate: '', // Store custom start date
      customEndDate: '', // Store custom end date
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
    // Detect browser timezone
    const timezone = this.getBrowserTimezone()
    this.setState({ browserTimezone: timezone }, () => {
      this.updateData(this.state.initial_data)
    })
  }

  // Detect browser timezone using Intl API
  getBrowserTimezone = () => {
    try {
      return Intl.DateTimeFormat().resolvedOptions().timeZone
    } catch (e) {
      // Fallback if Intl API is not available
      return null
    }
  }

  // Convert IANA timezone to friendly name
  getFriendlyTimezoneName = (timezone) => {
    if (!timezone) return ''

    // Map common IANA timezones to friendly names
    const timezoneMap = {
      'America/New_York': 'Eastern Time',
      'America/Chicago': 'Central Time',
      'America/Denver': 'Mountain Time',
      'America/Phoenix': 'Arizona Time',
      'America/Los_Angeles': 'Pacific Time',
      'America/Anchorage': 'Alaska Time',
      'Pacific/Honolulu': 'Hawaii Time',
      'America/Toronto': 'Eastern Time (Toronto)',
      'America/Vancouver': 'Pacific Time (Vancouver)',
      'Europe/London': 'British Time',
      'Europe/Paris': 'Central European Time',
      'Asia/Tokyo': 'Japan Time',
      'Australia/Sydney': 'Sydney Time',
      'UTC': 'UTC'
    }

    // Return the friendly name if available, otherwise return the last part of the timezone
    return timezoneMap[timezone] || timezone.split('/').pop().replace(/_/g, ' ')
  }

  urlFromFilters = () => {
    let url = this.state.api_root + "?filter=true"
    for (var filter of this.state.data.filters.options._index) {
      for (var p of this.state.data.filters[filter]) {
        url = `${url}&${this.state.data.filters.options[filter].param}[]=${p.val}`
      }
    }

    // Add custom date parameters if custom date range is selected
    const hasCustomDateRange = this.state.data.filters.date_range &&
      this.state.data.filters.date_range.some(range => range.val === 'custom')

    if (hasCustomDateRange) {
      if (this.state.customStartDate) {
        url = url + "&start_date[]=" + encodeURIComponent(this.state.customStartDate)
      }
      if (this.state.customEndDate) {
        url = url + "&end_date[]=" + encodeURIComponent(this.state.customEndDate)
      }
    }

    // Always include timezone parameter if available
    if (this.state.browserTimezone) {
      url = url + "&timezone[]=" + encodeURIComponent(this.state.browserTimezone)
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

  handleCustomDateChange = (startDate, endDate) => {
    this.setState(
      {
        customStartDate: startDate,
        customEndDate: endDate
      },
      () => {
        // Update data when custom dates change
        this.updateData(this.urlFromFilters())
        const newurl = this.urlFromFilters().replace('.json', '')
        window.history.pushState("", "Manager Dashboard", newurl)
      }
    )
  }

  render() {
    return(
      <div className={ Style.ManagerDashboard }>
        <Filters
          filters={this.state.data.filters}
          onFilter={this.updateFilter}
          browserTimezone={this.state.browserTimezone}
          getFriendlyTimezoneName={this.getFriendlyTimezoneName}
          customStartDate={this.state.customStartDate}
          customEndDate={this.state.customEndDate}
          onCustomDateChange={this.handleCustomDateChange}
        />
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
