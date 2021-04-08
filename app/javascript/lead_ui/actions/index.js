import axios from 'axios'

export const DEFAULT_ACTION = 'DEFAULT_ACTION'
export const REQUEST_LEAD = 'REQUEST_LEAD'
export const RECEIVE_LEAD = 'RECEIVE_LEAD'

export function initialFetchLead(search) {
  return function(dispatch){
    dispatch(requestLead(search))
    return axios.get(search.url)
      .then(response => {
        window.disableLoader()
        dispatch(receiveLead(response.data))
      })
      .catch(error => {
        // TODO: display error to user
        console.log(error)
      })
  }
}

export function fetchLead(search) {
  return function(dispatch){
    dispatch(requestLead(search))
    return axios.get(search.url)
      .then(response => {
        window.disableLoader()
        dispatch(receiveLead(response.data))
      })
      .catch(error => {
        // TODO: display error to user
        console.log(error)
      })
  }
}

export function receiveLead(data) {
  return {
    type: RECEIVE_LEAD,
    payload: {
      lead: data,
      updated: Date.now()
    }
  }
}

export function requestLead(search) {
  return {
    type: REQUEST_LEAD,
    payload: search
  }
}
