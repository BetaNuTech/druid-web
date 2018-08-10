json.data do
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
end
