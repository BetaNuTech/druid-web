import React from 'react'
import Style from './ManagerDashboard.scss'
import axios from 'axios'
import SourcesStats from './SourcesStats.jsx'
import SimpleBar from './SimpleBar.jsx'
import GroupedBar from './GroupedBar.jsx'

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
        },
        grouped_bar: {
          data: {
            series: [
              { label: "Foo", val: {total: 5, converted: 3 }},
              { label: "Bar", val: {total: 10, converted: 6}},
              { label: "Quux", val: {total: 12, converted: 4}},
              { label: "Acme", val: {total: 20, converted: 12}},
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
        <SimpleBar data={this.state.data.sources_stats.data}
          selectX={datum => datum.label}
          selectY={datum => datum.val}
          height={ 300 }
          width={ 400 }
        />
        <GroupedBar data={this.state.data.grouped_bar.data}
          selectX={datum => datum.label}
          selectY={datum => datum.val}
          height='300'
          width='500'
          yAxisLabel='Widgets'
        />
      </div>
    )
  }

}

export default ManagerDashboard
