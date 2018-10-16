json.search @search.full_options
json.data do
  json.array! @search.paginated, partial: 'leads/lead', as: :lead
end
json.url request.original_url
json.base_url request.original_url.split('?')[0]
