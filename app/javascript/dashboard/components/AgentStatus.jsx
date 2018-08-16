import React from 'react'
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

  render() {
    return(
      <div className={Style.AgentStatus}>
        <h4>Agent Status</h4>
      </div>
    )
  }
}

export default AgentStatus
