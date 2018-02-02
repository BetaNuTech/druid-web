import React from 'react'
import Style from './LeadSearchLead.scss'

class LeadSearchLead extends React.Component {
  constructor(props) {
    super(props)
    this.state = { data: props.data }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({data: nextProps.data})
  }

  render() {
    const agent = this.state.data.user ?
    <span><strong>Agent:</strong> {this.state.data.user.name}</span> :
    <span>Unclaimed</span>
    return(
      <div className={Style.LeadSearchLead} key={this.state.data.id}>
        <div className={Style.priority}>
          {this.state.data.state}<br/>
          {this.state.data.priority}<br/>
          {agent}
        </div>
        <div className={Style.contact}>
          <span className={Style.lead_name}>
            {this.state.data.title}&nbsp;
            {this.state.data.first_name}&nbsp;
            {this.state.data.last_name}
          </span><br/>
          <span className={Style.contact_info}>
            <span className="glyphicon glyphicon-earphone" />&nbsp;
            {this.state.data.phone1}<br/>
            <span className="glyphicon glyphicon-earphone" />&nbsp;
            {this.state.data.phone2}<br/>
            <span className="glyphicon glyphicon-envelope" />&nbsp;
            {this.state.data.email}<br/>
            <span className="glyphicon glyphicon-file" />&nbsp;
            {this.state.data.fax}
          </span>
        </div>
      </div>
    );
  }
}

export default LeadSearchLead
