import React from 'react'
import Lead from '../containers/Lead'

class App extends React.Component {
  render() {
    return(
      <Lead lead_id={this.props.lead_id} api_url={this.props.api_url}/>
    )
  }
}

export default App
