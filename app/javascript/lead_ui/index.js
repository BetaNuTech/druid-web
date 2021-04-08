import React from 'react'
import ReactDOM from 'react-dom'
import thunkMiddleware from 'redux-thunk'
import { createLogger } from 'redux-logger'
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux'
import App from './components/App'
import rootReducer from './reducers'

const loggerMiddleware = createLogger()
const store = createStore(
  rootReducer,
  applyMiddleware(thunkMiddleware, loggerMiddleware)
)
const domid = '#LeadUI'
const dom_el = document.querySelector(domid)
const lead_id = dom_el.dataset.lead_id
const lead_endpoint = `/leads/${lead_id}.json`
const lead_api_url = window.location.origin + lead_endpoint

ReactDOM.render(
  <Provider store={store}>
    <App lead_id={lead_id} api_url={lead_api_url}/>
  </Provider>,
  dom_el
)
