import React from 'react'
import Style from './LeadSearchLead.scss'
import moment from 'moment'
import LeadActions from './LeadActions.jsx'
import LeadComments from './LeadComments.jsx'

class LeadSearchLead extends React.Component {

  formatDate = (date) => {
    const thedate = moment(date)
    const formatter = "MM/DD/YYYY"
    return thedate.format(formatter)
  }

  formatDateTime = (date) => {
    const thedate = moment(date)
    const formatter = "MM/DD/YYYY hh:mm a"
    return thedate.format(formatter)
  }

  render() {
    return(
      <div className={Style.LeadSearchLead} key={this.props.data.id}>
        <div className={Style.priority}>
          <ul>
            <li>
              <strong>Priority:</strong>
              &nbsp;
              <span>{this.props.data.priority}</span>
            </li>
            <li>
              <strong>State:</strong>
              &nbsp;
              <span>{this.props.data.state}</span>
            </li>
            <li>
              <strong>Agent:</strong>
              &nbsp;
              <span>{this.props.data.user ? this.props.data.user.name : 'None'} </span>
            </li>
            <li>
              <strong>First Contact</strong>
              &nbsp;
              <span>{this.props.data.first_comm != undefined ? this.formatDateTime(this.props.data.first_comm) : '-'}</span>
            </li>
            <li>
              <strong>Last Contact:</strong>
              &nbsp;
              <span>{this.props.data.last_comm != undefined ? this.formatDateTime(this.props.data.last_comm) : '-'}</span>
            </li>
          </ul>
        </div>
        { false && <LeadActions lead_id={this.props.data.id} /> }
        <div className={Style.contact} >
          <span className={Style.lead_name}>
            <a href={this.props.data.web_url} target="_blank">
            {this.props.data.title}&nbsp;
            {this.props.data.first_name}&nbsp;
            {this.props.data.last_name}
          </a>
          </span><br/>
          <span className={Style.contact_info} >
            <span title="Primary Phone" className="glyphicon glyphicon-earphone" />&nbsp;
            {this.props.data.phone1}<br/>
            <span title="Secondary Phone" className="glyphicon glyphicon-earphone" />&nbsp;
            {this.props.data.phone2}<br/>
            <span title="Email Address" className="glyphicon glyphicon-envelope" />&nbsp;
            {this.props.data.email}<br/>
            <span title="Fax Number" className="glyphicon glyphicon-file" />&nbsp;
            {this.props.data.fax}
          </span>
        </div>
        <div className={Style.property}>
          {
            this.props.data.property ?
            <React.Fragment>
              <span>
                <span className="glyphicon glyphicon-home" />&nbsp;
                <a href={this.props.data.property.web_url} target="_blank">
                  {this.props.data.property.name}
                </a>
              </span><br/>
              <span>
                <span className="glyphicon glyphicon-download-alt" />&nbsp;
                {this.props.data.property.source}
              </span><br/>
            </React.Fragment> :
            <span>No Property<br/></span>
          }
          <span>
            <span className="glyphicon glyphicon-user" />&nbsp;
            {this.props.data.referral}
          </span>
        </div>
        <div className={Style.preferences}>
          <span>
            <strong>Move-In: </strong>
            {this.formatDate(this.props.data.preference.move_in)}
          </span><br/>
          <span><strong>Price: </strong>
            ${this.props.data.preference.min_price} - ${this.props.data.preference.max_price}
          </span><br/>
          <span><strong>Unit Size: </strong>
            {this.props.data.preference.min_area} - {this.props.data.preference.max_area}
          </span><br/>
        </div>
        <div className={Style.notes}>
          <p className={Style.notes.lead_notes}>
            <strong>Lead Notes: </strong>
            <span>
              {this.props.data.preference.notes}
            </span>
          </p>
          <p className={Style.notes.lead_notes}>
            <strong>Agent Notes: </strong>
            <span>
              {this.props.data.notes}
            </span>
          </p>
        </div>
        { false && <LeadComments lead_id={this.props.data.id} /> }
      </div>
    );
  }
}

export default LeadSearchLead
