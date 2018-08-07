import React from 'react'
import Style from './ManagerDashboard.scss'
import axios from 'axios'
import SourcesStats from './SourcesStats.jsx'

class ManagerDashboard extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      api_root: '/stats',
      data: {
        sources_stats: {
          data: {
            series: [
              { label: "Foo", value: 2},
              { label: "bar", value: 5},
              { label: "Quux", value: 7},
              { label: "Acme", value: 4}
            ]
          }
        }
      }
    }
  }

  render() {
    return(
      <div className="Style.ManagerDashboard">
        <h1>Manager Dashboard</h1>
        <SourcesStats data={this.state.data.sources_stats.data}
          selectX={datum => datum.label}
          selectY={datum => datum.value}
          height={ 300 }
          width={ 500 }
        />
      </div>
    )
  }

}

export default ManagerDashboard
