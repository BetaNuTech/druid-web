import React from 'react'
import PropTypes from 'prop-types'
import Style from './AgentStatus.scss'

class AgentStatus extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      data: this.props.data.data
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({data: nextProps.data.data})
  }

  leadSearchLink(userid) {
    return(`/leads/search?lead_search[user_ids][]=${userid}`)
  }

  agentRows(){
    return(this.state.data.series.map( d =>
      <tr key={d.id}>
        <td>{d.label}</td>
        <td>
          <em>Week:</em> {d.weekly_score}<br/>
          <em>Total:</em> {d.total_score}
        </td>
        <td>
          <em>Completed:</em> {d.tasks_completed}<br/>
          <em>Pending:</em> {d.tasks_pending}<br/>
        </td>
        <td>
          <em>Claimed:</em>&nbsp;
            <a href={this.leadSearchLink(d.id)} target="_blank">{d.claimed_leads}</a><br/>
          <em>Closed:</em>&nbsp;
            <a href={this.leadSearchLink(d.id)} target="_blank">{d.closed_leads}</a><br/>
        </td>
      </tr>
    ))
  }

  render() {
    return(
      <div className={Style.AgentStatus}>
        <h4>Agent Status (Week)</h4>
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Score</th>
              <th>Tasks</th>
              <th>Leads</th>
            </tr>
          </thead>
          <tbody>
            {this.agentRows()}
          </tbody>
        </table>
      </div>
    )
  }
}

AgentStatus.propTypes = {
  data: PropTypes.object.isRequired
}

AgentStatus.defaultProps = {
  data: { data: { series: [] } }
}

export default AgentStatus
