import { DEFAULT_ACTION, REQUEST_LEAD, RECEIVE_LEAD } from '../actions'

export default function(state, action){
  switch(action.type) {
    case DEFAULT_ACTION:
      return state

    case REQUEST_LEAD:
      return Object.assign({}, state, {
        loading: true
      })

    case RECEIVE_LEAD:
      return Object.assign({}, state, {
        lead: action.payload.lead,
        lead_id: action.payload.lead.id,
        loading: false,
        updated: action.payload.updated
      })

    default:
      return state
  }
}

