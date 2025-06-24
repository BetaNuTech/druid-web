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
      <div className={Style.LeadSearchLead} key={this.props.data.id} data-priority={this.props.data.priority}>
        <div className={Style.priority}>
          <ul>
            <li>
              <strong>Priority:</strong>
              <span className={`priority-${this.props.data.priority}`}>{this.props.data.priority}</span>
            </li>
            <li>
              <strong>State:</strong>
              <span className={`state-${this.props.data.state}`}>{this.props.data.state}</span>
            </li>
            <li>
              <strong>Agent:</strong>
              <span>{this.props.data.user ? this.props.data.user.name : 'None'}</span>
            </li>
            <li>
              <strong>First Contact:</strong>
              <span>{this.props.data.first_comm != undefined ? this.formatDateTime(this.props.data.first_comm) : '-'}</span>
            </li>
            <li>
              <strong>Last Contact:</strong>
              <span>{this.props.data.last_comm != undefined ? this.formatDateTime(this.props.data.last_comm) : '-'}</span>
            </li>
          </ul>
        </div>
        <div className={Style.contact} >
          <span className={Style.lead_name}>
            {
              this.props.data.vip == true ?
              <React.Fragment>
                <span className={Style.vip_icon}><span className="glyphicon glyphicon-heart" aria-hidden="true"> </span></span>
              </React.Fragment> : <span></span>
            }
            <a href={this.props.data.web_url}>
              {this.props.data.title}&nbsp;
              {this.props.data.first_name}&nbsp;
              {this.props.data.last_name}
            </a>
          </span>
          <br/>
          <span>
            <strong>
              &nbsp;&nbsp;
              {this.props.data.company}&nbsp;
              {this.props.data.company_title}&nbsp;
            </strong>
            { this.props.data.company != undefined || this.props.data.company_title != undefined ? <br/> : '' }
          </span>
          <LeadActions lead_id={this.props.data.id} lead_state={this.props.data.state} />
          <br/>
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
                <a href={this.props.data.property.web_url} >
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
            ${this.props.data.preference.max_price || 'Any'}
          </span><br/>
          <span><strong>Beds/Baths: </strong>
            {this.props.data.preference.beds || '?'} beds / {this.props.data.preference.baths || '?'} baths
          </span><br/>
          <span><strong>Unit Size: </strong>
            {this.props.data.preference.min_area || 'Any' } <i>ft<sup>2</sup></i>
            &nbsp;-&nbsp;
            {this.props.data.preference.max_area || 'Any'} <i>ft<sup>2</sup></i>
          </span><br/>
        </div>
        <div className={Style.notes}>
          <p className={Style.lead_notes}>
            <strong>Lead Notes: </strong>
            {this.props.data.preference.notes}
          </p>
        </div>
        <LeadComments lead_id={this.props.data.id} comments={this.props.data.comments} />
      </div>
    );
  }
}

export default LeadSearchLead
