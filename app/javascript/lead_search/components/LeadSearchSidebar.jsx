import React from 'react';
import Style from './LeadSearchSidebar.scss';

class LeadSearchSidebar extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      options: props.options
    };
  }

  componentWillReceiveProps(nextProps) {
    this.setState( { options: nextProps.options });
  }

  getAgents() {
    const filters = this.state.options.Filters;
    let agents = [];
    if (filters != undefined && filters.Agents != undefined) {
    }
  }

  agentFilters() {
    const filters = this.state.options.Filters;
    if (filters != undefined && filters.Agents != undefined) {
      return filters.Agents.values.map((agent) =>
        <strong>Agent:</strong>
      );
    } else {
      return "No Agent Filters";
    }
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

export default LeadSearchSidebar;
