import React from 'react'
import Style from './LeadSearchLeads.scss'
import LeadSearchLead from './LeadSearchLead.jsx'

class LeadSearchLeads extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      data: props.data
    }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({data: nextProps.data})
  }

  render() {
    let leads = <h3>None Found</h3>
    if (this.state.data.length > 0) {
      leads = this.state.data.map((lead) => {
        return <LeadSearchLead data={lead} key={lead.id}/>
      })
    }


    return(
      <div className={Style.LeadSearchLeads}>
        <div className={Style.ResultsTableHeader}> </div>
        <div className={Style.ResultsTable}>
          {leads}
        </div>
      </div>
    );
  }
}

export default LeadSearchLeads
