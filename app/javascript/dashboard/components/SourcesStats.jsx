import React from 'react'
import Style from './SourcesStats.scss'
import d3 from 'd3'

const SourcesStats = ({data, height, width, selectX, selectY}) => {
  return(
    <div className="Style.SourcesStats">
      <h2>Source Stats</h2>
      <br/>
      Data:
      <pre>
        {JSON.stringify(data)}
      </pre>
      <div className="Style.chart">
        <svg
          className="SourcesStats"
          height={height}
          width={width}
        >

        </svg>
      </div>
    </div>
  )
}

export default SourcesStats
