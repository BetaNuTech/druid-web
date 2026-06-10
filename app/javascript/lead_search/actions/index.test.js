import axios from 'axios'
import MockAdapter from 'axios-mock-adapter'
import {
  initialFetchLeads,
  fetchLeads,
  receiveLeads,
  updateTextSearch,
  TEXT_SEARCH,
  REQUEST_LEADS,
  RECEIVE_LEADS
} from './index'

// These tests run against the real axios request pipeline (only the
// transport is mocked), so they verify axios behavior our code depends
// on: axios.get, axios.defaults.baseURL, and the response.data shape.
describe('lead_search actions', () => {
  let mock
  let dispatched
  let dispatch

  const serverResponse = {
    data: [{ id: 'lead-1', first_name: 'John' }],
    meta: { total_pages: 1 },
    search: {
      Filters: { _index: [] },
      Pagination: { _index: [] }
    },
    base_url: 'http://localhost',
    url: '/leads/search.json'
  }

  beforeEach(() => {
    mock = new MockAdapter(axios)
    dispatched = []
    dispatch = (action) => dispatched.push(action)
    window.activateLoader = jest.fn()
    window.disableLoader = jest.fn()
    window.scrollTo = jest.fn()
  })

  afterEach(() => {
    mock.restore()
    delete axios.defaults.baseURL
  })

  describe('updateTextSearch', () => {
    it('creates a TEXT_SEARCH action', () => {
      expect(updateTextSearch('John')).toEqual({ type: TEXT_SEARCH, payload: 'John' })
    })
  })

  describe('receiveLeads', () => {
    it('merges base_url and url into the search payload', () => {
      const action = receiveLeads(serverResponse)
      expect(action.type).toEqual(RECEIVE_LEADS)
      expect(action.payload.search.base_url).toEqual('http://localhost')
      expect(action.payload.search.url).toEqual('/leads/search.json')
      expect(action.payload.collection).toEqual(serverResponse.data)
      expect(action.payload.meta).toEqual(serverResponse.meta)
    })
  })

  describe('initialFetchLeads', () => {
    it('dispatches REQUEST_LEADS then RECEIVE_LEADS with the response data', async () => {
      const search = { url: '/leads/search.json' }
      mock.onGet('/leads/search.json').reply(200, serverResponse)

      await initialFetchLeads(search)(dispatch)

      expect(dispatched.map((action) => action.type)).toEqual([REQUEST_LEADS, RECEIVE_LEADS])
      expect(dispatched[0].payload).toEqual(search)
      expect(dispatched[1].payload.collection).toEqual(serverResponse.data)
      expect(dispatched[1].payload.meta).toEqual(serverResponse.meta)
      expect(window.disableLoader).toHaveBeenCalled()
    })

    it('does not dispatch RECEIVE_LEADS when the request fails', async () => {
      const search = { url: '/leads/search.json' }
      mock.onGet('/leads/search.json').networkError()

      await initialFetchLeads(search)(dispatch)

      expect(dispatched.map((action) => action.type)).toEqual([REQUEST_LEADS])
    })
  })

  describe('fetchLeads', () => {
    const search = {
      base_url: 'http://localhost',
      url: '/leads/search.json',
      Filters: {
        _index: ['Search'],
        Search: { param: 'text', values: [{ label: 'John', value: 'John' }] }
      },
      Pagination: {
        _index: ['Page'],
        Page: { param: 'page', values: [{ label: 'Page', value: '2' }] }
      }
    }

    it('requests a URL built from search filters and pagination', async () => {
      mock.onGet().reply(200, serverResponse)

      await fetchLeads(search)(dispatch)

      expect(mock.history.get.length).toEqual(1)
      expect(mock.history.get[0].url).toEqual('?lead_search[text][]=John&lead_search[page][]=2')
      expect(axios.defaults.baseURL).toEqual('http://localhost')
    })

    it('dispatches REQUEST_LEADS then RECEIVE_LEADS and toggles the loader', async () => {
      mock.onGet().reply(200, serverResponse)

      await fetchLeads(search)(dispatch)

      expect(dispatched.map((action) => action.type)).toEqual([REQUEST_LEADS, RECEIVE_LEADS])
      expect(dispatched[1].payload.collection).toEqual(serverResponse.data)
      expect(window.activateLoader).toHaveBeenCalled()
      expect(window.disableLoader).toHaveBeenCalled()
    })

    it('URL-encodes filter values', async () => {
      const accentedSearch = {
        ...search,
        Filters: {
          _index: ['Search'],
          Search: { param: 'text', values: [{ label: 'José & Co', value: 'José & Co' }] }
        }
      }
      mock.onGet().reply(200, serverResponse)

      await fetchLeads(accentedSearch)(dispatch)

      expect(mock.history.get[0].url).toContain(encodeURIComponent('José & Co'))
    })

    it('does not dispatch RECEIVE_LEADS when the request fails', async () => {
      mock.onGet().networkError()

      await fetchLeads(search)(dispatch)

      expect(dispatched.map((action) => action.type)).toEqual([REQUEST_LEADS])
    })
  })
})
