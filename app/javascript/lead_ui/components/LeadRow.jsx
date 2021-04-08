import React from 'react'
import Style from './LeadRow.scss'

class LeadRow extends React.Component {
  constructor(props) {
    super(props)
    this.state = { expanded: true }
  }

  toggleEnabled() {
    return(this.props.toggle == 'true' || this.props.toggle === undefined)
  }

  displayContent() {
    return(
      <div className={this.state.expanded ? Style.LeadRowContent : Style.LeadRowContentMinimized}>
        {this.props.children}
      </div>
    )
  }

  displayControls() {
    return(
      <div className={Style.LeadRowControls}>
        {this.addLink()}
        {this.toggleEnabled() ? this.viewToggleButton() : ''}
      </div>
    )
  }

  toggleView = (event) => {
    event.preventDefault()
    this.setState(state => ({
      expanded: !state.expanded
    }))
    return(true)
  }

  viewToggleButton() {
    return(
      <a href="#" onClick={this.toggleView}>
        <img src={"/icons/chevron_" + (this.state.expanded ? 'up' : 'down') + ".svg"} width={this.iconSize()}></img>
      </a>
    )
  }

  addLink() {
    return(
      this.props.add === undefined ? '' :
      <a href={this.props.add} _target="blank">
        <img src="/icons/plus.svg" width="30px"></img>
      </a>
    )
  }

  iconSize() {
    return(`${this.props.iconSize === undefined ? 20 : this.props.iconSize}px`)
  }

  render(){
    return(
      <div className={Style.LeadRow + " row" } >
        {this.displayControls()}
        {this.displayContent()}
      </div>
    )
  }
}

export default LeadRow
