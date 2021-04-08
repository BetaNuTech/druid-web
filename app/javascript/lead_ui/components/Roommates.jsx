import React from 'react'
import Style from './Roommates.scss'
import LeadRow from './LeadRow'

class Roommates extends React.Component {

  roommateEntry(roommate) {
    return(
      <div key={roommate.id} className="row">
        <div className="col-md-12">
          <h4>{roommate.first_name} {roommate.last_name}</h4>
          <div className="row">
            <div className="col-md-6">
              <div className="row">
                <div className="col-md-6">
                  <span className="badge badge-info">{roommate.occupancy}</span>&nbsp;
                  <span className="badge badge-info">{roommate.relationship}</span>
                </div>
                <div className="col-md-6">
                  { this.phoneNumber(roommate.phone_formatted, roommate.sms_allowed) }
                  { this.email(roommate.email, roommate.email_allowed) }
                </div>
              </div>
            </div>
            <div className="col-md-6">
              {this.roommateEditLink(roommate)}
              <tt> { roommate.notes }</tt>
            </div>
          </div>
        </div>
      </div>
    )
  }

  roommateEditLink(roommate) {
    const url = `/leads/${this.props.lead.id}/roommates/${roommate.id}/edit`
    return(<a href={url} _target='blank' style={ { text_decoration: 'none' } }><img src="/icons/pencil_assign.svg" /></a>)
  }

  roomateAddLink() {
    return(`/leads/${this.props.lead.id}/roommates/new`)
  }

  hasRoommates() {
    if (this.props.lead === undefined) return(false)
    if (this.props.lead.roommates === undefined) return(false)
    if (this.props.lead.roommates.length == 0) return(false)
    return(true)
  }

  render() {
    const roommateItems = this.hasRoommates() ? this.props.lead.roommates.map((roommate) => this.roommateEntry(roommate)) : <p>(none)</p>
    return(
      <div className={Style.Roommates}>
        <LeadRow add={this.roomateAddLink()}>
          <div className="col-md-12">
            <b>Roommates/Guarantors</b>
            {roommateItems}
          </div>
        </LeadRow>
      </div>
    )
  }

  phoneNumber(phone, allowed) {
    if (phone === undefined || phone == '' || phone == ' ' || phone == null) {
      return('')
    } else {
      const sms_icon = allowed ? <img src="/icons/message.svg"/> : ''
      return(
        <span>
          <img src="/icons/phone.svg"/>&nbsp;
          {sms_icon}
          <b> <a href={"tel:" + phone}>{phone}</a></b>
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

}

export default Roommates
