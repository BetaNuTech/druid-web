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

  leadSearchLink(userid, states, start_date, end_date) {
    let state_filter = '';
    for (const state of states) {
      state_filter += `&lead_search[states][]=${state}`
    }
    return(`/leads/search?lead_search[user_ids][]=${userid}&lead_search[start_date][]=${start_date}&lead_search[end_date][]=${end_date}${state_filter}`)
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
          <em>On Time:</em> {Math.round( d.task_completion_rate * 100.0 )}%<br/>
        </td>
        <td>
          <em>Working:</em>&nbsp;
            <a href={this.leadSearchLink(d.id, ['prospect', 'showing', 'application', 'approved', 'denied'] ,d.start_date, d.end_date)} target="_blank">{d.worked_leads}</a><br/>
          <em>Closed:</em>&nbsp;
            <a href={this.leadSearchLink(d.id, ['invalidated', 'future', 'waitlist'], d.start_date, d.end_date)} target="_blank">{d.closed_leads}</a><br/>
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
