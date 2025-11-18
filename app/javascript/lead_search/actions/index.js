import axios from 'axios'

export const TEXT_SEARCH = 'TEXT_SEARCH'
export const REQUEST_LEADS = 'REQUEST_LEADS'
export const RECEIVE_LEADS = 'RECEIVE_LEADS'
export const GOTO_PAGE = 'GOTO_PAGE'
export const UPDATE_SEARCH = 'UPDATE_SEARCH'

export function updateTextSearch(text_string) {
  return {
    type: TEXT_SEARCH,
    payload: text_string
  }
}

export function initialFetchLeads(search) {
  return function(dispatch){
    dispatch(requestLeads(search))
    return axios.get(search.url)
      .then(response => {
        window.disableLoader()
        dispatch(receiveLeads(response.data))
        updateUrl(search.url)
      })
      .catch(error => {
        // TODO: display error to user
        console.log(error)
      })
  }
}

export function requestLeads(search) {
  return {
    type: REQUEST_LEADS,
    payload: search
  }
}

export function receiveLeads(data) {
  const search_data = {
    ...data.search,
    base_url: data.base_url,
    url: data.url }
  return {
    type: RECEIVE_LEADS,
    payload: {search: search_data, collection: data.data, meta: data.meta}
  }
}

export function fetchLeads(search) {
  return function(dispatch){
    dispatch(requestLeads(search))
    axios.defaults.baseURL = search.base_url
    const url = urlParamsFromSearch(search)
		window.activateLoader()
    return axios.get(url)
      .then(response => {
        window.disableLoader()
        dispatch(receiveLeads(response.data))
        updateUrl(url)
        window.scrollTo({top: 0, behavior: "smooth"})
      })
      .catch(error => {
        // TODO: display error to user
        console.log(error)
      })
  }
}

export function gotoPage(search) {
  return function(dispatch) {
    return function(page) {
      const newSearch = {
        ...search,
        Pagination: {
          ...search.Pagination,
          Page: {
            ...search.Pagination.Page,
            values: [{label: "Page", value: page}]
          }
        }
      }
      dispatch(updateSearch(newSearch))
      dispatch(fetchLeads(newSearch))
    }
  }
}

export function updateSortKey(search) {
  return function(dispatch) {
    return function(value) {
      const newSearch = {
        ...search,
        Pagination: {
          ...search.Pagination,
          SortBy: {
            ...search.Pagination.SortBy,
            values: [{label: 'Sort By', value: value}]
          }
        }
      }
      dispatch(updateSearch(newSearch))
      dispatch(fetchLeads(newSearch))
    }
  }
}

export function updateSortDirection(search) {
  return function(dispatch) {
    return function(value) {
      const newSearch = {
        ...search,
        Pagination: {
          ...search.Pagination,
          SortDir: {
            ...search.Pagination.SortDir,
            values: [{label: 'Sort Direction', value: value}]
          }
        }
      }
      dispatch(updateSearch(newSearch))
      dispatch(fetchLeads(newSearch))
    }
  }
}

export function updateFilter(search) {
  return function(dispatch) {
    return function(filter,values) {
        if (search.Filters === undefined) {
          return
        }
        const newSearch = {
          ...search,
          Filters: {
            ...search.Filters,
            [filter]: {
              ...search.Filters[filter],
              values: values
            }
          }
        }
        dispatch(updateSearch(newSearch))
        return
      }
  }
}

export function updateSearch(search) {
  return {
    type: UPDATE_SEARCH,
    payload: search
  }
}

export function updateSearchString(search) {
  return function(dispatch) {
    return function(search_string) {
      if (search.Filters === undefined) {
        return
      }

      let new_values
      if (search_string) {
        new_values = [{label: search_string, value: search_string}]
      } else {
        new_values = []
      }

      const newSearch = {
        ...search,
        Filters: {
          ...search.Filters,
          Search: {
            ...search.Filters.Search,
            values: new_values
          }
        }
      }
      dispatch(updateSearch(newSearch))
    }
  }
}

export function submitSearch(search) {
  return function(dispatch) {
    return function() {
      dispatch(fetchLeads(search))
    }
  }
}

export function resetFilters(search) {
  return function(dispatch) {
    if ( search.Filters === undefined ) return
    let newSearch = Object.assign({}, search,{})
    newSearch.Filters._index.forEach((filter) => {
      newSearch.Filters[filter].values = []
    })
    dispatch(updateSearch(newSearch))
  }
}

// Private methods

function updateUrl(url) {
  let new_url = url.replace("search.json","search")
  history.replaceState({turbolinks: {}}, "Lead Search", new_url)
}

function urlParamsFromSearch(search) {
  let filterParams = paramsFromSearchNode(search.Filters)
  let paginationParams = paramsFromSearchNode(search.Pagination)
  let output = "?" + [...filterParams, ...paginationParams].join("&")
  return output
}

function paramsFromSearchNode(segment) {
  const search_param = "lead_search"
  let params = []
  if (segment === undefined) {
    return []
  }

  // Process filters from _index
  if (segment._index) {
    segment._index.forEach(function(key) {
      if (segment[key] && segment[key]["param"]) {
        let param = segment[key]["param"]
        segment[key]["values"].forEach(function(val) {
          let value = ''
          if (val["value"] != undefined) {
            value = val["value"]
          } else {
            value = val
          }
          if (value.length > 0) {
            let safeVal = encodeURIComponent(value)
            params.push(`${search_param}[${param}][]=${safeVal}`)
          }
        })
      }
    })
  }

  // Also include timezone if it exists but isn't in _index
  if (segment.timezone && segment.timezone.values && segment.timezone.values.length > 0) {
    let hasTimezone = false
    if (segment._index) {
      hasTimezone = segment._index.includes('timezone')
    }
    if (!hasTimezone) {
      segment.timezone.values.forEach(function(val) {
        let value = val.value || val
        if (value.length > 0) {
          let safeVal = encodeURIComponent(value)
          params.push(`${search_param}[timezone][]=${safeVal}`)
        }
      })
    }
  }

  return params
}
