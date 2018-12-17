json.Meta do
  json.ReportDate DateTime.now
  json.Version "1.1"
end

case @stats_for
  when 'properties'
    json.Properties @stats.property_stats
  when 'agents'
    json.Users @stats.agent_stats
  when 'teams'
    json.Teams @stats.team_stats
end
