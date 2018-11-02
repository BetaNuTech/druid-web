json.Meta do
  json.ReportDate DateTime.now
  json.Version "1.0"
end
json.Properties @stats.property_stats
json.Users @stats.agent_stats
json.Teams @stats.team_stats
