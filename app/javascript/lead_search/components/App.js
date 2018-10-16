import React from "react"
import LeadSearch from "../containers/LeadSearch"

class App extends React.Component {
  render() {
    const endpoint =  "/leads/search.json"
    const base_url = window.location.origin + endpoint
    const search_url = base_url + window.location.search
    return <LeadSearch search={ { url: search_url, base_url: base_url }}/>
  }
}

export default App
