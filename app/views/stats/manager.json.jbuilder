json.links do
  json.self request.original_url
  json.api @stats.url
end

json.data do
  json.filters @stats.filters_json

  json.lead_sources do
    json.data do
      json.series @stats.lead_sources_conversion_json
    end
  end

  json.lead_states do
    json.data do
      json.series @stats.lead_states_json
    end
  end

  json.agent_conversion_rates do
    json.data do
      json.series @stats.agent_conversion_rates_json
    end
  end

  json.referral_conversion_rates do
    json.data do
      json.series @stats.referral_conversion_rates_json
    end
  end

  json.response_times do
    json.data do
      json.series @stats.response_times_json
    end
  end

  json.property_leads do
    json.data do
      json.series @stats.property_leads_json
    end
  end

  json.open_leads do
    json.data @stats.open_leads_json
  end

  json.agent_status do
    json.data @stats.agent_status_json
  end

  json.recent_activity do
    json.data @stats.recent_activity_json
  end
end
