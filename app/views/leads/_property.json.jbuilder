json.extract! property, :id, :name
if source.present?
  json.source source.name
  json.remoteid property.listing_code(source)
  json.url property_url(id: property.id, format: :json)
  json.web_url property_url(id: property.id)
else
  json.source json.nil!
  json.remoteid json.nil!
end
