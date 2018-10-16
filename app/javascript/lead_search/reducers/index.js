import { REQUEST_LEADS, RECEIVE_LEADS, UPDATE_SEARCH } from '../actions'

export default function(state, action){
  switch(action.type) {
    case REQUEST_LEADS:
      return Object.assign({}, state, {
        loading: true,
        pending_update: false
      })

    case RECEIVE_LEADS:
      return Object.assign({}, state, {
        search: action.payload.search,
        collection: action.payload.collection,
        loading: false,
        pending_update: false
      })

    case UPDATE_SEARCH:
      return Object.assign({}, state, {
        search: action.payload,
        pending_update: true
      })

    default:
      return state
  }
}

