import React from 'react'
import Style from './LeadSearchSidebar.scss'

class LeadSearchSidebar extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      options: props.options
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState( { options: nextProps.options })
  }

  getAgents = () => {
    let filters = this.state.options.Filters
    let agents = []
    if (filters && filters.Agents) {
      agents = filters.Agents.values
    }
    return agents
  }

  getFilterData = (key) => {
    let filters = this.state.options.Filters
    return (filters && filters[key]) ? filters[key].values  : []
  }

  agentFilters = () => {
    const agents = this.getFilterData("Agents")
    let output = ""
    if (agents.length > 0) {
      output = agents.map((agent) => {
        return <span key={agent.value}>
          <strong>Agent:</strong> {agent.label}
        </span>
      })
    } else {
      output = <span>Any</span>
    }
    return output
  }

  filterInfo = (key) => {
    const values = this.getFilterData(key)
    let output = ""
    if (values.length > 0) {
      output = values.map((value) => {
        return <li key={value.value}>{value.label}</li>
      })
    } else {
      output = <li>Any</li>
    }
    return output
  }

  render() {
    return(
      <div className={Style.LeadSearchSidebar}>
        <strong>Priority</strong>
        <ul>
          {this.filterInfo("Priorities")}
        </ul>
        <strong>Agent</strong>
        <ul>
          {this.filterInfo("Agents")}
        </ul>
        <strong>Property</strong>
        <ul>
          {this.filterInfo("Properties")}
        </ul>
        <strong>State</strong>
        <ul>
          {this.filterInfo("States")}
        </ul>
      </div>
    );
  }
}

export default LeadSearchSidebar
