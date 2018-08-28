import React from 'react'
import PropTypes from 'prop-types'
import Style from './RecentActivity.scss'

class RecentActivity extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      data: this.props.data.data
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({data: nextProps.data.data})
  }

  activityRows = () => {
    return(this.state.data.map(d =>
      <tr key={d.raw_date}>
        <td>{d.agent_name}</td>
        <td>{d.date}</td>
        <td>{d.entry_type}</td>
        <td>
          <a href={d.link} target="_blank">
            {d.description}
          </a>
        </td>
      </tr>
      )
    )
  }


  render(){
    return(
      <div className={Style.RecentActivity}>
        <h4>Recent Activity (48h)</h4>
        <table className="table">
          <thead>
            <tr>
              <th>Agent</th>
              <th>Date</th>
              <th>Type</th>
              <th>Description</th>
            </tr>
          </thead>
          <tbody>
            {this.activityRows()}
          </tbody>
        </table>
      </div>
    )
  }

}

RecentActivity.propTypes = {
  data: PropTypes.object.isRequired
}

RecentActivity.defaultProps = {
  data: {data: []}
}

export default RecentActivity
