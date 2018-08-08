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
              { label: "Foo", val: 2},
              { label: "bar", val: 5 },
              { label: "Quux", val: 10 },
              { label: "Acme", val: 4},
              { label: "Test", val: 12}
            ]
          }
        }
      }
    }
  }

  render() {
    return(
      <div className={ Style.ManagerDashboard }>
        <h1>Manager Dashboard</h1>
        <SourcesStats data={this.state.data.sources_stats.data}
          selectX={datum => datum.label}
          selectY={datum => datum.val}
          height={ 300 }
          width={ 400 }
        />
      </div>
    )
  }

}

export default ManagerDashboard
