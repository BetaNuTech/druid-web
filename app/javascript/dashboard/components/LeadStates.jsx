import React from 'react'
import Style from './LeadStates.scss'

import { scaleLinear, scaleBand, scaleOrdinal } from 'd3-scale'
import { schemeCategory10 } from 'd3'

import { max, extent } from 'd3-array'
import { select } from 'd3-selection'
import { axisBottom, axisLeft} from 'd3-axis'

class LeadStates extends React.Component {
  constructor(props) {
    super(props)
    this.margin = {top: 20, bottom: 70, left: 50, right: 20}
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

  leadSearchLink = (state_name) => {
    let property_filter = ""
    let user_filter = ""
    if (this.props.filters != undefined && this.props.filters.properties.length > 0) {
      for (var p of this.props.filters.properties) {
        property_filter = property_filter + `&lead_search[property_ids][]=${p.val}`
      }
    }
    if (this.props.filters != undefined && this.props.filters.users.length > 0) {
      for (var p of this.props.filters.users) {
        user_filter = user_filter + `&lead_search[user_ids][]=${p.val}`
      }
    }
    return(`/leads/search?lead_search[states][]=${state_name}${property_filter}${user_filter}`)
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
    chart.append("g")
      .attr("class", "axis axis--x")
      .attr("transform", `translate(${this.margin.left},${this.margin.top + this.height})`)
      .call(axisBottom(xScale))
      .selectAll("text")
        .attr("transform", "rotate(-45)")
        .style("text-anchor", "end")
    // Add Vertical (y) Axis labels
    chart.append("g")
      .attr("class", "axis axis--y")
      .attr("transform", `translate(${this.margin.left},${this.margin.top})`)
      .call(axisLeft(yScale))
  }

  addAxesLabels = () => {
    const chart = select(this.node)
    chart
      .append("text")
      .attr("transform", `translate(${this.props.width / 2}, ${this.props.height - 5})`)
        .attr("text-anchor", "middle")
        .text(this.xAxisLabel)
    chart
      .append("text")
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
    const bar = chart.selectAll(".bar").data(this.props.data.series)
    const yScale = this.getYScale()
    const xScale = this.getXScale()
    const colorScale = this.getColorScale()

    this.addAxes()

    // Add Bars
    bar
      .enter()
        .append('rect')
        .merge(bar)
          .attr("transform", `translate(${this.margin.left},${this.margin.top})`)
          .attr('class', 'bar')
          .style('fill', d => colorScale(this.props.selectX(d)))
          .attr('x', d => xScale(this.props.selectX(d)))
          .attr('y', d => yScale(this.props.selectY(d)))
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
        .merge(bar)

    // Add values to bars
    bar
      .enter()
        .append("text")
        .merge(bar)
          .attr('text-anchor', "middle")
          .attr("x", d => this.margin.left + xScale(this.props.selectX(d)) + xScale.bandwidth()/2)
          .attr("y", d => this.margin.top + yScale(this.props.selectY(d)) - 5)
          .text(d => this.props.selectY(d) )

    bar.exit().remove()
  }

  render(){
    return(
      <div className={Style.LeadStates}>
        <svg ref={node => this.node = node}
          className="bargraph"
          height={this.props.height}
          width={this.props.width}
        >
        </svg>
      </div>
    )
  }


}


export default LeadStates
