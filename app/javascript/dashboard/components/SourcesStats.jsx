import React from 'react'
import Style from './SourcesStats.scss'

import { scaleLinear, scaleBand } from 'd3-scale'
import { max, extent } from 'd3-array'
import { select } from 'd3-selection'
import { axisBottom, axisLeft} from 'd3-axis'

class SourcesStats extends React.Component {
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

    // Vertical (y) axis for values
    const yScale = scaleLinear().
      domain([0, max(this.props.data.series, this.props.selectY)]).
      range([this.height, 0])

    // Horizontal (x) Axis for labels
    const xScale = scaleBand().
      domain(this.props.data.series.map(this.props.selectX)).
      rangeRound([0, this.width]).
      padding(0.2)

    // Position chart with margin
    const chart = select(node)
      chart.attr("transform", "translate(" + this.margin.top + "," + this.margin.left + ")")

    // Add Horizontal (x) Axis labels
    chart.append("g")
      .attr("class", "axis axis--x")
      .attr("transform", "translate(0," + this.height + ")")
      .call(axisBottom(xScale))

    // Add Vertical (y) Axis labels
    chart.append("g")
      .attr("class", "axis axis--y")
      .call(axisLeft(yScale))

    var bar = chart.selectAll(".bar")
      .append("g")
        .attr("transform", "translate(0," + this.height + ")")

    bar
      .data(this.props.data.series)
      .enter()
        .append('rect')
          .attr('class', 'bar')
          .style('fill', '#cccccc')
          .style('stroke', '#000')
          .attr('x', d => xScale(this.props.selectX(d)))
          .attr('y', d => yScale(this.props.selectY(d)))
          .attr('height', d => this.height - yScale(this.props.selectY(d)))
          .attr('width', xScale.bandwidth())

      /*
    select(node)
      .selectAll('rect')
      .data(this.props.data.series)
      .enter().append('rect')
        .style('fill', '#cccccc')
        .attr('x', d => xScale(this.props.selectX(d)))
        .attr('y', d => this.height - yScale(this.props.selectY(d)))
        .attr('height', d => yScale(this.props.selectY(d)))
        .attr('width', xScale.bandwidth())
      */
  }

  render(){
    return(
      <div className={Style.SourcesStats}>
        <h2>Source Stats</h2>
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


export default SourcesStats
