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
const domid = '#LeadSearch'

ReactDOM.render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.querySelector(domid)
)
