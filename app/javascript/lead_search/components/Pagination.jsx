import React from 'react'
import Style from './Pagination.scss'

class Pagination extends React.Component {

  totalPages(){
    let totalpages= 0
    if (this.props.search.Pagination) {
      totalpages = this.props.search.Pagination._total_pages
    }
    return totalpages
  }

  currentPage() {
    let currentpage = 1
    if (this.props.search.Pagination) {
      currentpage = this.props.search.Pagination.Page.values[0].value
    }
    return currentpage
  }

  handleClickPageNumber = (event) => {
    event.preventDefault()
    const page = event.target.dataset.pagenumber
    if (page <= this.totalPages()) {
      this.props.onGotoPage(page)
    }
  }

  render() {
    let maxPages = this.totalPages()
    let pageArray = Array.apply(null, {length: maxPages}).map(Number.call, Number)
    let pageNumbers = pageArray.map((p) => {
        let linkClass = "btn " + (this.currentPage() == p + 1 ? "btn-info" : "btn-default");
        let linkKey = "LeadsPage" + p
      return <a href="#" className={linkClass} key={linkKey}
                data-pagenumber={p + 1} onClick={this.handleClickPageNumber}>
              {p + 1}</a>
      }
    )

    return(
      <div className={Style.Pagination}>
        <p>
          Page {this.currentPage()} of {this.totalPages()}
        </p>
        <a href="#" className="btn btn-default" data-pagenumber={this.currentPage() + 1} onClick={this.handleClickPageNumber}>Next</a>
        {pageNumbers}
      </div>
    )
  }
}

export default Pagination
