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
    let leads = this.state.data.map((lead) => {
      return <LeadSearchLead data={lead} key={lead.id}/>
    })

    return(
      <div className="LeadSearchLeads">
        <div className="ResultsTableHeader">
          {leads.length} Leads
        </div>
        <div class="ResultsTable">
          {leads}
        </div>
      </div>
    );
  }
}

export default LeadSearchLeads
