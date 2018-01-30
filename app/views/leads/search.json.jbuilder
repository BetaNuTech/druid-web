json.search @search.full_options
json.data do
  json.array! @search.paginated
end
