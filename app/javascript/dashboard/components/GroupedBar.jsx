import React from 'react'
import Style from './GroupedBar.scss'

import { scaleLinear, scaleBand, scaleOrdinal } from 'd3-scale'
import { schemePaired } from 'd3'

import { max, extent } from 'd3-array'
import { select } from 'd3-selection'
import { axisBottom, axisLeft} from 'd3-axis'

class GroupedBar extends React.Component {
  constructor(props) {
    super(props)
    this.margin = {top: 20, bottom: 20, left: 20, right: 20}
    this.width = +this.props.width - this.margin.left - this.margin.right
    this.height = +this.props.height - this.margin.top - this.margin.bottom
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
    let margin_top = this.margin.top
    let margin_bottom = this.margin.bottom
    let margin_left = this.margin.left
    let margin_right = this.margin.right
    let width = this.width
    let height = this.height

    const node = this.node
    const chart = select(node)

    const selectY = this.props.selectY
    const selectX = this.props.selectX

    // Data Value Keys
    let keys = []
    if (this.props.data.series[0] != undefined) {
      keys = Object.keys(selectY(this.props.data.series[0])) }
    // Adjust bar height to account for legend
    margin_top = margin_top + keys.length * 30
    height = this.height - margin_top - margin_bottom

    // Horizontal (x0) Axis for groups of bars
    const xScaleGroup = scaleBand()
      .domain(this.props.data.series.map(selectX))
      .rangeRound([0, this.width])
      .paddingInner(0.1)

    // Horizontal (x1) Axis for bars
    const xScaleBar = scaleBand()
      .domain(keys)
      .rangeRound([0,xScaleGroup.bandwidth()])
      .padding(0.05)


    let maxValue = max(this.props.data.series,
                        d => max(keys,
                                  key => selectY(d)[key] ))
    console.log({maxValue: maxValue})

    // Vertical (y) axis for values
    const yScale = scaleLinear()
      .range([height, 0])
      .domain([0, maxValue])

    const colorScale = scaleOrdinal(schemePaired)

    // Position chart with margin
    chart.attr("transform", "translate(" + margin_left + "," + margin_top + ")")

    // Add Horizontal (x) Axis
    chart.append("g")
      .attr("class", "axis axis--x")
      .attr("transform", `translate(${margin_left},${margin_top + height})`)
      .call(axisBottom(xScaleGroup))

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
        .text(this.props.yAxisLabel)

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
        .attr("x", 10 )
        .attr("width", 15)
        .attr("height", 15)
        .attr("fill", d => colorScale(keys.indexOf(d)))

    //// Add Legend Key Labels
    legend
      .append("text")
        .attr("x", 30)
        .attr("y", 10)
        .attr("dy", "0.1em")
        .text(d => d)
  }

  render(){
    return(
      <div className={Style.SourcesStats}>
        <h2>Grouped Bar Chart</h2>
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


export default GroupedBar
