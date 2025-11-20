import React from 'react'
import './CustomDateRange.scss'

class CustomDateRange extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      startDate: props.startDate || '',
      endDate: props.endDate || ''
    }
  }

  componentDidUpdate(prevProps) {
    if (prevProps.startDate !== this.props.startDate || prevProps.endDate !== this.props.endDate) {
      this.setState({
        startDate: this.props.startDate || '',
        endDate: this.props.endDate || ''
      })
    }
  }

  handleStartDateChange = (e) => {
    const newValue = e.target.value
    this.setState({ startDate: newValue })

    // Validate that start date is not after end date
    if (this.state.endDate && newValue > this.state.endDate) {
      this.props.onChange(newValue, newValue)
      this.setState({ endDate: newValue })
    } else {
      this.props.onChange(newValue, this.state.endDate)
    }
  }

  handleEndDateChange = (e) => {
    const newValue = e.target.value
    this.setState({ endDate: newValue })

    // Validate that end date is not before start date
    if (this.state.startDate && newValue < this.state.startDate) {
      this.props.onChange(newValue, newValue)
      this.setState({ startDate: newValue })
    } else {
      this.props.onChange(this.state.startDate, newValue)
    }
  }

  render() {
    const { visible } = this.props

    if (!visible) {
      return null
    }

    return (
      <div className="custom-date-range">
        <div className="date-input-group">
          <div className="date-input-wrapper">
            <label htmlFor="start-date">Start Date</label>
            <input
              id="start-date"
              type="date"
              className="form-control date-input"
              value={this.state.startDate}
              onChange={this.handleStartDateChange}
              max={this.state.endDate || undefined}
            />
          </div>
          <div className="date-input-wrapper">
            <label htmlFor="end-date">End Date</label>
            <input
              id="end-date"
              type="date"
              className="form-control date-input"
              value={this.state.endDate}
              onChange={this.handleEndDateChange}
              min={this.state.startDate || undefined}
            />
          </div>
        </div>
      </div>
    )
  }
}

export default CustomDateRange