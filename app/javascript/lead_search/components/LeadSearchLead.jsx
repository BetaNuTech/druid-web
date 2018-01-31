import React from 'react';
import Style from './LeadSearchLead.scss';

class LeadSearchLead extends React.Component {
  constructor(props) {
    super(props)
    this.state = { data: props.data }
  }

  componentWillReceiveProps(nextProps) {
    this.setState({data: nextProps.data})
  }

  render() {
    return(
      <div className="LeadSearchLead" key={this.state.data.id}>
        <h2>Lead</h2>
        <strong>ID:</strong> {this.state.data.id}
      </div>
    );
  }
}

export default LeadSearchLead
