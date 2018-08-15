import React from 'react'
import Style from './LeadSources.scss'

import { scaleLinear, scaleBand, scaleOrdinal } from 'd3-scale'
import { schemePaired } from 'd3'

import { max, extent } from 'd3-array'
import { select } from 'd3-selection'
import { axisBottom, axisLeft} from 'd3-axis'

class LeadSources extends React.Component {
  constructor(props) {
    super(props)
    this.margin = {top: 50, bottom: 40, left: 50, right: 20}
    this.width = +this.props.width - this.margin.left - this.margin.right
    this.height = +this.props.height - this.margin.top - this.margin.bottom
    this.yAxisLabel = this.props.yAxisLabel
    this.xAxisLabel = this.props.xAxisLabel
  }

  componentDidMount() {
    this.createBarChart()
  }

  componentDidUpdate() {
    this.createBarChart()
  }

  getDataKeys = () => {
    let keys = []
    if (this.props.data.series[0] != undefined) {
      keys = Object.keys(this.props.selectY(this.props.data.series[0])) }

    return(keys)
  }

  getYScale = () => {
    let maxYValue = max(this.props.data.series,
                        d => max(this.getDataKeys(),
                                  key => this.props.selectY(d)[key] ))
    return(scaleLinear()
      .range([this.height, 0])
      .domain([0, maxYValue]))
  }

  getXScaleGroup = () => {
    return(scaleBand()
      .domain(this.props.data.series.map(this.props.selectX))
      .rangeRound([0, this.width])
      .paddingInner(0.1))
  }

  getXScaleBar = () => {
    return(scaleBand()
      .domain(this.getDataKeys())
      .rangeRound([0,this.getXScaleGroup().bandwidth()])
      .padding(0.05))
  }

  getColorScale = () => {
    return(scaleOrdinal(schemePaired))
  }

  createBarChart = () => {
    let margin_top = this.margin.top
    let margin_bottom = this.margin.bottom
    let margin_left = this.margin.left
    let margin_right = this.margin.right
    let width = this.width
    let height = this.height
    let yAxisLabel = this.yAxisLabel
    let xAxisLabel = this.xAxisLabel

    const chart = select(this.node)

    const selectY = this.props.selectY
    const selectX = this.props.selectX

    let keys = this.getDataKeys()

    const xScaleGroup = this.getXScaleGroup()

    const xScaleBar = this.getXScaleBar()

    const yScale = this.getYScale()
    const colorScale = this.getColorScale()

    // Add Horizontal (x) Axis
    chart.append("g")
      .attr("class", "axis axis--x")
      .attr("transform", `translate(${margin_left},${margin_top + height})`)
      .call(axisBottom(xScaleGroup))

    chart
      .append("text")
      .attr("transform", `translate(${width / 2}, ${this.props.height})`)
        .attr("text-anchor", "middle")
        .text("Lead Source")

    // Add Vertical (y) Axis
    chart.append("g")
      .attr("class", "axis axis--y")
      .attr("transform", `translate(${margin_left},${margin_top})`)
      .call(axisLeft(yScale))

    // Add Vertical (y) Axis Label
    chart
      .append("text")
        .attr("class", "axis-label--y")
        .attr("transform", `translate(${margin_left + 20},${margin_top}) rotate(-90)`)
        .attr("text-anchor", "end")
        .text(yAxisLabel)

    // Position Bars
    var bar = chart.selectAll(".bar")
      .append("g")
        .attr("transform", `translate(${margin_left},${margin_top})`)

    // Add Bars
    bar
      .data(this.props.data.series)
      .enter()
        .append("g")
          .attr("class", d => `bargroup bargroup--${selectX(d)}`)
          .attr("transform", d => `translate(${xScaleGroup(selectX(d))},0)`)
      .selectAll(".bar")
      .data(d => keys.map(key => ( {key: key, value: selectY(d)[key], index: keys.indexOf(key)} )))
      .enter()
        .append("rect")
          .attr("class", ".bar")
          .attr("x", d => xScaleBar(d.key) )
          .attr("y", d => yScale(d.value) )
          .attr("width", xScaleBar.bandwidth())
          .attr("height", d => height - yScale(d.value))
          .attr("fill", d => colorScale(d.index))
          .attr("transform", `translate(${margin_left},${margin_top})`)

    // Add Values
    bar
      .data(this.props.data.series)
      .enter()
        .append("g")
          .attr("class", "bargroup--values")
          .attr("transform", d => `translate(${margin_left + xScaleGroup(selectX(d))},${margin_top})`)
      .selectAll(".label--value")
      .data(d => keys.map(key => ( {key: key, value: selectY(d)[key]} )))
      .enter()
        .append("text")
          .attr("class", "label--value")
          .attr('text-anchor', "middle")
          .attr("x", d => xScaleBar(d.key) + xScaleBar.bandwidth()/2 )
          .attr("y", d => yScale(d.value) - 5 )
          .text(d => d.value)

    // Add Legend
    const legend = chart.append("g")
        .attr("class","legend")
        .attr("font-size", 10)
      .selectAll("g")
      .data(keys)
      .enter()
        .append("g")
          .attr("class", "legend--key")
          .attr("transform", (d,i) => `translate(0,${i * 20 })`)

    //// Add Legend Keys
    legend
      .append("rect")
        .attr("x", margin_left + 10 )
        .attr("width", 15)
        .attr("height", 15)
        .attr("fill", d => colorScale(keys.indexOf(d)))

    //// Add Legend Key Labels
    legend
      .append("text")
        .attr("x", margin_left + 30)
        .attr("y", 10)
        .attr("dy", "0.1em")
        .text(d => d)
  }

  render(){
    return(
      <div className={Style.LeadSources}>
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


export default LeadSources
