import React from 'react'
import PropTypes from 'prop-types'
import Style from './PropertyLeads.scss'

import { scaleLinear, scaleBand, scaleOrdinal } from 'd3-scale'
import { schemeCategory10 } from 'd3'

import { max, extent } from 'd3-array'
import { select } from 'd3-selection'
import { axisBottom, axisLeft} from 'd3-axis'

class PropertyLeads extends React.Component {
  constructor(props) {
    super(props)
    this.margin = {top: 20, bottom: 120, left: 50, right: 20}
    this.width = +this.props.width - this.margin.left - this.margin.right
    this.height = +this.props.height - this.margin.top - this.margin.bottom
    this.yAxisLabel = this.props.yAxisLabel
    this.xAxisLabel = this.props.xAxisLabel
  }

  componentDidMount() {
    this.createBarChart()
  }

  componentDidUpdate() {
    this.updateBarChart()
  }

  leadSearchLink = (property_id) => {
    let user_filter = ""
    if (this.props.filters != undefined && this.props.filters.users.length > 0) {
      for (var p of this.props.filters.users) {
        user_filter = user_filter + `&lead_search[user_ids][]=${p.val}`
      }
    }
    return(`/leads/search?lead_search[property_ids][]=${property_id}${user_filter}`)
  }

  openLinkInTab = (link) => {
    window.open(link, '_blank')
  }

  handleBarMouseUp = (d) => {
    this.openLinkInTab(this.leadSearchLink(d.id))
  }

  handleMouseOver(d,i) {
    select(this)
      .attr("opacity", "0.5")
  }

  handleMouseOut(d,i) {
    select(this)
      .attr("opacity", "1.0")
  }
  getYScale = () => {
    // Vertical (y) axis for values
    return(scaleLinear().
      domain([0, max(this.props.data.series, this.props.selectY)]).
      range([this.height, 0]))
  }

  getXScale = () => {
    return(scaleBand().
      domain(this.props.data.series.map(this.props.selectX)).
      rangeRound([0, this.width]).
      padding(0.2))
  }

  getColorScale = () => {
    return(scaleOrdinal(schemeCategory10))
  }

  addAxes = () => {
    const chart = select(this.node)
    const yScale = this.getYScale()
    const xScale = this.getXScale()
    const colorScale = this.getColorScale()
    // Add Horizontal (x) Axis labels
    chart.select("g.axis--x")
      .attr("class", "axis axis--x")
      .attr("transform", `translate(${this.margin.left},${this.margin.top + this.height})`)
      .call(axisBottom(xScale))
      .selectAll("text")
        .attr("transform", "rotate(-45)")
        .style("text-anchor", "end")
    // Add Vertical (y) Axis labels
    chart.select("g.axis--y")
      .attr("class", "axis axis--y")
      .attr("transform", `translate(${this.margin.left},${this.margin.top})`)
      .call(axisLeft(yScale))
  }

  addAxesLabels = () => {
    const chart = select(this.node)
    chart
      .select("text.axis--x-label")
      .attr("transform", `translate(${this.props.width / 2}, ${this.props.height - 5})`)
        .attr("text-anchor", "middle")
        .text(this.xAxisLabel)
    chart
      .select("text.axis--y-label")
      .attr("transform", `translate(20,${this.height / 2}) rotate(-90)`)
        .attr("text-anchor", "end")
        .text(this.yAxisLabel)
  }

  createBarChart = () => {
    this.updateBarChart()
    this.addAxesLabels()
  }

  updateBarChart = () => {
    const chart = select(this.node)
    //const bar = chart.selectAll(".bar").data(this.props.data.series)
    const yScale = this.getYScale()
    const xScale = this.getXScale()
    const colorScale = this.getColorScale()

    this.addAxes()

    // Add Bars
    const bar = chart.selectAll(".bar").data(this.props.data.series)
    bar.exit().remove()
    bar
      .enter()
        .append('rect')
        .merge(bar)
          .attr('class', 'bar')
          .style('fill', d => colorScale(this.props.selectX(d)))
          .attr('x', d => this.margin.left + xScale(this.props.selectX(d)))
          .attr('y', d => this.margin.top + yScale(this.props.selectY(d)))
          .attr('height', d => this.height - yScale(this.props.selectY(d)))
          .attr('width', xScale.bandwidth())
          .on("mouseup", d => this.handleBarMouseUp(d))
          .on("mouseover", this.handleMouseOver)
          .on("mouseout", this.handleMouseOut)
        .append("text")
        .merge(bar)
          .attr('text-anchor', "middle")
          .attr("x", d => this.margin.left + xScale(this.props.selectX(d)) + xScale.bandwidth()/2)
          .attr("y", d => this.margin.top + yScale(this.props.selectY(d)) - 5)
          .text(d => this.props.selectY(d) )

    // Add values to bars
    const barvalues = chart.selectAll(".barvalue").data(this.props.data.series)
    barvalues.exit().remove()
    barvalues
      .enter()
        .append("text")
        .merge(barvalues)
          .attr("class", "barvalue")
          .attr("font-size", 11)
          .attr('text-anchor', "middle")
          .attr("x", d => this.margin.left + xScale(this.props.selectX(d)) + xScale.bandwidth()/2)
          .attr("y", d => this.margin.top + yScale(this.props.selectY(d)) - 5)
          .text(d => this.props.selectY(d) )

    this.noDataAdvisory()
  }


  noDataAdvisory = () => {
    const chart = select(this.node)
    if (this.props.data.series.length == 0) {
      chart.select("text.advisory")
        .attr("font-size", 20)
        .attr("x", this.width / 3)
        .attr("y", this.props.height / 2)
        .text("No Data")
    } else {
      chart.select("text.advisory")
        .text("")
    }
  }


  render(){
    return(
      <div className={Style.PropertyLeads}>
        <svg  ref={node => this.node = node}
              className="bargraph"
              height={this.props.height}
              width={this.props.width} >
          <g className="axis axis--x"></g>
          <g className="axis axis--y"></g>
          <g>
            <text className="axis--x-label"/>
            <text className="axis--y-label"/>
          </g>
          <g className="advisory">
            <text className="advisory"/>
          </g>
        </svg>
      </div>
    )
  }


}

PropertyLeads.defaultProps = {
  filters: {},
  selectX: () => {},
  selectX: () => {},
  height: 300,
  width: 300,
  yAxisLabel: '',
  xAxisLabel: ''
}

export default PropertyLeads
