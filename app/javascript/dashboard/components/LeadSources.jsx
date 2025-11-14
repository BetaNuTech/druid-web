import React from 'react'
import PropTypes from 'prop-types'
import Style from './LeadSources.scss'

import { scaleLinear, scaleBand, scaleOrdinal } from 'd3-scale'
import { schemePaired } from 'd3'

import { max, extent } from 'd3-array'
import { select } from 'd3-selection'
import { axisBottom, axisLeft } from 'd3-axis'

class LeadSources extends React.Component {
  constructor(props) {
    super(props)
    this.margin = {top: 60, bottom: 120, left: 65, right: 20}
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

  leadSearchLink = (source_id) => {
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
    return(`/leads/search?lead_search[sources][]=${source_id}${property_filter}${user_filter}`)
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

  getDataKeys = () => {
    let keys = []
    if (this.props.data.series[0] != undefined) {
      keys = Object.keys(this.props.selectY(this.props.data.series[0])) }

    return(keys)
  }

  getYScale = () => {
    const maxYValue = max(this.props.data.series,
                        d => max(this.getDataKeys(),
                                  key => this.props.selectY(d)[key] ))
    return(scaleLinear()
      .rangeRound([this.height, 0])
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

  addAxes = () => {
    const chart = select(this.node)
    const xScaleGroup = this.getXScaleGroup()
    const yScale = this.getYScale()

    // Add Horizontal (x) Axis
    chart.select("g.axis--x")
      .attr("class", "axis axis--x")
      .attr("transform", `translate(${this.margin.left},${this.margin.top + this.height})`)
      .call(axisBottom(xScaleGroup))
      .selectAll("text")
        .attr("transform", "rotate(-45)")
        .style("text-anchor", "end")

    // Add Vertical (y) Axis
    chart.select("g.axis--y")
      .attr("class", "axis axis--y")
      .attr("transform", `translate(${this.margin.left},${this.margin.top})`)
      .call(axisLeft(yScale))
  }

  addAxesLabels = () => {
    const chart = select(this.node)

    // Add Horizontal (x) Axis Label
    chart.select("text.axis--x-label")
      .attr("transform", `translate(${this.props.width / 2}, ${this.props.height})`)
      .attr("text-anchor", "middle")
      .text(this.xAxisLabel)

    // Add Vertical (y) Axis Label
    chart.select("text.axis--y-label")
      .attr("transform", `translate(20,${this.margin.top + ( this.height) / 2}) rotate(-90)`)
      .attr("text-anchor", "middle")
      .text(this.yAxisLabel)
  }

  addLegend = () => {
    const chart = select(this.node)
    const keys = this.getDataKeys()
    const colorScale = this.getColorScale()
    const legend = chart.select("g.legend")

    const legendkeys = legend.selectAll("rect.legend--key").data(keys)
    legendkeys.exit().remove()
    legendkeys
      .enter()
      .append("rect")
      .merge(legendkeys)
        .attr("class", "legend--key")
        .attr("x", this.margin.left + 10 )
        .attr("y", (d,i) => i * 20 )
        .attr("width", 15)
        .attr("height", 15)
        .attr("fill", d => colorScale(keys.indexOf(d)))

    const legendkeylabels = legend.selectAll("text.legend--keylabel").data(keys)
    legendkeylabels.exit().remove()
    legendkeylabels
      .enter()
      .append("text")
      .merge(legendkeylabels)
        .attr("class", "legend--keylabel")
        .attr("x", this.margin.left + 30)
        .attr("y", (d,i) => i * 20 + 10 )
        .attr("dy", "0.1em")
        .text(d => d)
  }

  updateBarChart = () => {
    const chart = select(this.node)
    const xScaleGroup = this.getXScaleGroup()
    const xScaleBar = this.getXScaleBar()
    const yScale = this.getYScale()
    const keys = this.getDataKeys()
    const colorScale = this.getColorScale()

    this.addAxes()
    this.addLegend()

    chart.selectAll("g.bargroup").remove()
    const bargroups = chart.selectAll("g.bargroup").data(this.props.data.series)
    bargroups.exit().remove()
    bargroups
      .enter()
      .append("g")
      .merge(bargroups)
        .attr("class", "bargroup")
        .attr("transform", d => `translate(${xScaleGroup(this.props.selectX(d))},0)`)
      .selectAll(".bar")
      .data(d => keys.map(key => ( {id: d.id, key: key, value: this.props.selectY(d)[key], index: keys.indexOf(key)} )))
      .enter()
        .append("rect")
          .attr("class", "bar")
          .attr("x", d => xScaleBar(d.key) )
          .attr("y", d => yScale(d.value) )
          .attr("width", xScaleBar.bandwidth())
          .attr("height", d => this.height - yScale(d.value))
          .attr("fill", d => colorScale(d.index))
          .attr("transform", `translate(${this.margin.left},${this.margin.top})`)
          .on("mouseup", d => this.handleBarMouseUp(d))
          .on("mouseover", this.handleMouseOver)
          .on("mouseout", this.handleMouseOut)

    // Create value label groups
    const valueLabelGroups = chart.selectAll("g.bargroup--values")
      .data(this.props.data.series)

    valueLabelGroups.exit().remove()

    const valueLabelGroupsEnter = valueLabelGroups
      .enter()
        .append("g")
          .attr("class", "bargroup--values")

    const valueLabelGroupsMerged = valueLabelGroupsEnter.merge(valueLabelGroups)
      .attr("transform", d => `translate(${this.margin.left + xScaleGroup(this.props.selectX(d))},${this.margin.top})`)

    // Create value labels within each group
    const valueLabels = valueLabelGroupsMerged.selectAll("text.label--value")
      .data(d => {
        const values = keys.map((key, index) => ({
          key: key,
          value: this.props.selectY(d)[key],
          originalValue: this.props.selectY(d)[key],  // Keep original for display decision
          index: index
        }))

        // Check if bars are too close and would cause label overlap
        if (values.length === 2) {
          const val0 = values[0].originalValue
          const val1 = values[1].originalValue

          // Don't show 0 values
          if (val0 === 0) values[0].value = 0
          if (val1 === 0) values[1].value = 0

          // If both values are non-zero, check for overlap
          if (val0 > 0 && val1 > 0) {
            const y0 = yScale(val0)
            const y1 = yScale(val1)

            // If labels would be within 20 pixels of each other, only show the larger value
            if (Math.abs(y0 - y1) < 20) {
              if (val0 >= val1) {
                values[1].value = 0  // Hide smaller value label
              } else {
                values[0].value = 0  // Hide smaller value label
              }
            }
          }
        }

        return values
      })

    valueLabels.exit().remove()

    valueLabels
      .enter()
        .append("text")
          .attr("class", "label--value")
      .merge(valueLabels)
          .attr("font-size", "11")
          .attr('text-anchor', "middle")
          .attr("x", d => xScaleBar(d.key) + xScaleBar.bandwidth()/2 )
          .attr("y", d => yScale(d.value) - 5 )
          .text(d => d.value > 0 ? d.value : '')  // Only show label if value > 0


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

  createBarChart = () => {
    this.addAxes()
    this.addAxesLabels()
    this.updateBarChart()
  }

  render(){
    return(
      <div className={Style.LeadSources}>
        <svg  ref={node => this.node = node}
              className="bargraph"
              height={this.props.height}
              width={this.props.width} >
          <g className="axis axis--x"></g>
          <g className="axis axis--y"></g>
          <g className="axis--labels">
            <text className="axis--x-label"/>
            <text className="axis--y-label"/>
          </g>
          <g className="advisory">
            <text className="advisory"/>
          </g>
          <g className="legend" fontSize="10">
          </g>
        </svg>
      </div>
    )
  }


}

LeadSources.propTypes = {
  filters: PropTypes.object.isRequired,
  selectX: PropTypes.func.isRequired,
  selectY: PropTypes.func.isRequired,
  height: PropTypes.number.isRequired,
  width: PropTypes.number.isRequired,
  yAxisLabel: PropTypes.string.isRequired,
  xAxisLabel: PropTypes.string.isRequired
}

LeadSources.defaultProps = {
  filters: {},
  selectX: () => {},
  selectX: () => {},
  height: 300,
  width: 300,
  yAxisLabel: '',
  xAxisLabel: ''
}

export default LeadSources
