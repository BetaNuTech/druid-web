json.search @search.full_options
json.data do
  json.array! @search.paginated, partial: 'leads/lead', as: :lead
end
json.meta do
  json.version '1.0'
  json.generated_at DateTime.current
  json.total_count @search.record_count
  json.count @search.paginated.size
end
json.url request.original_url
json.base_url request.original_url.split('?')[0]
