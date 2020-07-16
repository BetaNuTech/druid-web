json.links do
  json.self request.original_url
  json.api @stats.url
end

json.data do
  json.filters @stats.filters_json

  case @report
  when 'lead_sources'
    json.lead_sources do
      json.data do
        json.series @stats.lead_sources_conversion_json
      end
    end
  when 'lead_states'
    json.lead_states do
      json.data do
        json.series @stats.lead_states_json
      end
    end
  when 'agent_conversion_rates'
    json.agent_conversion_rates do
      json.data do
        json.series @stats.agent_conversion_rates_json
      end
    end
  when 'referral_conversion_rates'
    json.referral_conversion_rates do
      json.data do
        json.series @stats.referral_conversion_rates_json
      end
    end
  when 'response_times'
    json.response_times do
      json.data do
        json.series @stats.response_times_json
      end
    end
  when 'property_leads'
    json.property_leads do
      json.data do
        json.series @stats.property_leads_json
      end
    end
  when 'open_leads'
    json.open_leads do
      json.data @stats.open_leads_json
    end
  when 'agent_status'
    json.agent_status do
      json.data @stats.agent_status_json
    end
  when 'recent_activity'
    json.recent_activity do
      json.data @stats.recent_activity_json
    end
  end
end
