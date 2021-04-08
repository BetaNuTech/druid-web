import React from 'react'
import Style from './LeadSummary.scss'
import LeadRow from './LeadRow'

class LeadSummary extends React.Component {
  summaryHeader() {
    if (this.props.lead === undefined) {
      return('')
    } else {
     return(
       <div className="row">
        <div className="col-md-6">
          <h2>
            {this.props.lead.first_name}&nbsp;
            {this.props.lead.last_name}
          </h2>
        </div>
        <div className="col-md-6 text-right">
          <h2>
            <img src="/icons/messages.svg" /> &nbsp;
            <img src="/icons/hourglass.svg" />
          </h2>
        </div>
       </div>
     )
    }
  }

  summary() {
    if (this.props.lead === undefined) {
      return('')
    } else {
      return(
        <LeadRow toggle='false'>
          <div className="col-md-12">
            <div className={Style.LeadSummaryHead + " row"}>
              <div className="col-md-12">
                <span className="badge badge-secondary">
                  {this.props.lead.state}
                </span>&nbsp;&nbsp;
                <span>
                  <img src="/icons/messages.svg" />&nbsp;
                  <b>{this.props.lead.last_comm_relative}</b>
                </span>&nbsp;&nbsp;
                <span>
                  <img src="/icons/user.svg" />&nbsp;
                  <b>{this.props.lead.user.name}</b>
                </span>&nbsp;&nbsp;
                <span>
                  <img src="/icons/referral_sources.svg" />&nbsp;
                  <b>{this.props.lead.referral}</b>
                </span>&nbsp;
              </div>
            </div>
            <div className="row">
              <div className="col-md-6">
                {this.phoneNumber(this.props.lead.phone1_formatted, this.props.lead.preference.sms_allowed)}
                {this.phoneNumber(this.props.lead.phone2_formatted, this.props.lead.preference.sms_allowed)}
                {this.email(this.props.lead.email, this.props.lead.preference.email_allowed)}
              </div>
              <div className="col-md-6">
                <span>
                  <img src="/icons/home.svg"/>&nbsp;&nbsp;
                  <b>{this.props.lead.property.name}</b>
                </span><br/>

                <span>
                  <img src="/icons/home.svg" />&nbsp;
                  Move-In:&nbsp;
                  <b>{this.props.lead.preference.move_in_date || '-'}</b><br/>
                </span>

                <span>
                  <img src="/icons/home.svg" />&nbsp;
                  Price:&nbsp;
                  <b>{this.props.lead.preference.price || '-'}</b><br/>
                </span>

                <span>
                  <img src="/icons/home.svg" />&nbsp;
                  Unit Size / Type:&nbsp;
                  <b>{this.props.lead.preference.floorplan_name || '-'}</b>
                </span>

              </div>
            </div>
          </div>
        </LeadRow>
      )
    }
  }

  phoneNumber(phone, allowed) {
    if (phone === undefined || phone == '' || phone == ' ' || phone == null) {
      return('')
    } else {
      const sms_icon = allowed ? <img src="/icons/message.svg"/> : ''
      return(
        <span>
          <img src="/icons/phone.svg"/>&nbsp;
          {sms_icon}&nbsp;
          <b><a href={"tel:" + phone}>{phone}</a></b>
          <br/>
        </span>
      )
    }
  }

  email(email, allowed) {
    if (!allowed || email === undefined || email == '' || email == ' ' || email == null ) {
      return('')
    } else {
      return(
        <span>
          <img src="/icons/email.svg" />&nbsp;
          <b>{email}</b>
          <br/>
        </span>
      )
    }
  }

  render() {
    return(
      <div className={Style.LeadSummary}>
        {this.summaryHeader()}
        {this.summary()}
      </div>
    )
  }
}

export default LeadSummary
