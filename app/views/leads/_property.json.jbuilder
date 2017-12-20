json.extract! property, :id, :name
if source.present?
  json.source source.name
  json.remoteid property.listing_code(source)
else
  json.source json.nil!
  json.remoteid json.nil!
end
