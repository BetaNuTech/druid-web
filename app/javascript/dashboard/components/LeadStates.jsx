import React from 'react'
import Style from './SimpleBar.scss'

import { scaleLinear, scaleBand, scaleOrdinal } from 'd3-scale'
import { schemePaired } from 'd3'

import { max, extent } from 'd3-array'
import { select } from 'd3-selection'
import { axisBottom, axisLeft} from 'd3-axis'

class SimpleBar extends React.Component {
  constructor(props) {
    super(props)
    this.margin = {top: 20, bottom: 70, left: 50, right: 20}
    this.width = +this.props.width - this.margin.left - this.margin.right
    this.height = +this.props.height - this.margin.top - this.margin.bottom
  }

  componentDidMount() {
    this.createBarChart()
  }

  componentDidUpdate() {
    this.createBarChart()
  }

  createBarChart = () => {
    let margin_top = this.margin.top
    let margin_bottom = this.margin.bottom
    let margin_left = this.margin.left
    let margin_right = this.margin.right
    let width = this.width
    let height = this.height

    const node = this.node

    // Remove previous chart
    select(node).select("svg").remove()

    const chart = select(node)
      .append("svg")
      .attr("class", "bargraph")
      .attr("width", this.props.width)
      .attr("height", this.props.height)

    // Vertical (y) axis for values
    const yScale = scaleLinear().
      domain([0, max(this.props.data.series, this.props.selectY)]).
      range([this.height, 0])

    // Horizontal (x) Axis for labels
    const xScale = scaleBand().
      domain(this.props.data.series.map(this.props.selectX)).
      rangeRound([0, this.width]).
      padding(0.2)

    const colorScale = scaleOrdinal(schemePaired)

    // Position chart with margin
    chart.attr("transform", "translate(" + margin_top + "," + margin_left + ")")

    // Add Horizontal (x) Axis labels
    chart.append("g")
      .attr("class", "axis axis--x")
      .attr("transform", `translate(${margin_left},${margin_top + this.height})`)
      .call(axisBottom(xScale))
      .selectAll("text")
        .attr("transform", "rotate(-45)")
        .style("text-anchor", "end")

    chart
      .append("text")
      .attr("transform", `translate(${width / 2}, ${this.props.height})`)
        .attr("text-anchor", "middle")
        .text("Lead State")

    // Add Vertical (y) Axis labels
    chart.append("g")
      .attr("class", "axis axis--y")
      .attr("transform", `translate(${margin_left},${margin_top})`)
      .call(axisLeft(yScale))

    chart
      .append("text")
        .attr("transform", `translate(${margin_left + 20},${margin_top}) rotate(-90)`)
        .attr("text-anchor", "end")
        .text("Leads")

    // Position Bars
    var bar = chart.selectAll(".bar")
      .append("g")
        .attr("transform", `translate(${margin_left},${margin_top})`)

    // Add Bars
    bar
      .data(this.props.data.series)
      .enter()
        .append('rect')
          .attr("transform", `translate(${margin_left},${margin_top})`)
          .attr('class', 'bar')
          .style('fill', d => colorScale(this.props.selectX(d)))
          .attr('x', d => xScale(this.props.selectX(d)))
          .attr('y', d => yScale(this.props.selectY(d)))
          .attr('height', d => this.height - yScale(this.props.selectY(d)))
          .attr('width', xScale.bandwidth())

    // Add values to bars
    bar
      .data(this.props.data.series)
      .enter()
        .append("text")
          .attr('text-anchor', "middle")
          .attr("x", d => margin_left + xScale(this.props.selectX(d)) + xScale.bandwidth()/2)
          .attr("y", d => margin_top + yScale(this.props.selectY(d)) - 5)
          .text(d => this.props.selectY(d) )

  }

  render(){
    return(
      <div ref={node => this.node = node} className={Style.SourcesStats}>
      </div>
    )
  }


}


export default SimpleBar
