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
        <h1>Leads Here</h1>
        {leads}
      </div>
    );
  }
}

export default LeadSearchLeads
