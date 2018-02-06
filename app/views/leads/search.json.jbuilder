json.search @search.full_options
json.data do
  json.array! @search.paginated, partial: 'leads/lead', as: :lead
end
