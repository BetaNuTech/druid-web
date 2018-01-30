import React from 'react';
import ReactDOM from 'react-dom';
import LeadSearch from './components/LeadSearch.jsx';

const lead_search = document.querySelector('#LeadSearch');
ReactDOM.render(<LeadSearch api="/leads/search.json" search_param="lead_search" />, lead_search);
