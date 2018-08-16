import React from 'react'
import Style from './OpenLeads.scss'

class OpenLeads extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      data: this.props.data.data
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({data: nextProps.data.data})
  }

  leadRows = () => {
    return(
      this.state.data.series.map((d) =>
        <tr key={d.id}>
          <td>
            <a href={d.url} target="_blank">
              {d.label}
            </a>
          </td>
          <td>
            via {d.source} &nbsp;
            {d.created_at} ago
          </td>
        </tr>
      )
    )
  }

  render() {
  console.log(this.leadRows())
    return(
      <div className={Style.OpenLeads}>
        <h4>
          Open Leads
          ({this.state.data.count} of {this.state.data.total})
        </h4>
        <hr/>
        <table className="table {Style.OpenLeadTable}">
          {this.leadRows()}
        </table>
      </div>
    )
  }
}

export default OpenLeads
