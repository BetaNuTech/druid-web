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
    this.margin = {top: 20, bottom: 20, left: 20, right: 20}
    this.width = this.props.width - this.margin.left - this.margin.right
    this.height = this.props.height - this.margin.top - this.margin.bottom
  }

  componentDidMount() {
    console.log("Component Mounted")
    this.createBarChart()
  }

  componentDidUpdate() {
    console.log("Component Updated")
    this.createBarChart()
  }

  createBarChart = () => {
    const node = this.node
    const chart = select(node)

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
    chart.attr("transform", "translate(" + this.margin.top + "," + this.margin.left + ")")

    // Add Horizontal (x) Axis labels
    chart.append("g")
      .attr("class", "axis axis--x")
      .attr("transform", `translate(${this.margin.left},${this.margin.top + this.height})`)
      .call(axisBottom(xScale))

    // Add Vertical (y) Axis labels
    chart.append("g")
      .attr("class", "axis axis--y")
      .attr("transform", `translate(${this.margin.left},${this.margin.top})`)
      .call(axisLeft(yScale))

    chart
      .append("text")
        .attr("transform", `translate(${this.margin.left + 20},${this.margin.top}) rotate(-90)`)
        .attr("text-anchor", "end")
        .text("Leads")

    // Position Bars
    var bar = chart.selectAll(".bar")
      .append("g")
        .attr("transform", `translate(${this.margin.left},${this.margin.top})`)

    // Add Bars
    bar
      .data(this.props.data.series)
      .enter()
        .append('rect')
          .attr("transform", `translate(${this.margin.left},${this.margin.top})`)
          .attr('class', 'bar')
          .style('fill', d => colorScale(this.props.selectX(d)))
          .style('stroke', '#000')
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
          .attr("x", d => this.margin.left + xScale(this.props.selectX(d)) + xScale.bandwidth()/2)
          .attr("y", d => this.margin.top + yScale(this.props.selectY(d)) - 5)
          .text(d => this.props.selectY(d) )

  }

  render(){
    return(
      <div className={Style.SourcesStats}>
        <h2>Simple Bar Chart</h2>
        <svg ref={node => this.node = node}
          className="bargraph"
          width={this.props.width}
          height={this.props.height}
        >

        </svg>
      </div>
    )
  }


}


export default SimpleBar
