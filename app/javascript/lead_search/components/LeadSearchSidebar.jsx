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
    const filters = this.state.options.Filters
    let agents = []
    if (filters != undefined && filters.Agents != undefined) {
      agents = filters.Agents.values
    }
    return agents
  }

  agentFilters() {
    let agents = this.getAgents()
    return agents.map((agent) => {
      <strong>Agent:</strong>
    })
  }

  render() {
    return(
      <div className={Style.LeadSearchSidebar}>
        <h3>Agents</h3>
        {this.agentFilters()}
      </div>
    );
  }
}

export default LeadSearchSidebar
