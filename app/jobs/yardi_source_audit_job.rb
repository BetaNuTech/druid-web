class YardiSourceAuditJob < ApplicationJob
  queue_as :default

  # Audit a single property's marketing sources against Yardi Voyager.
  # Enqueued when a MarketingSource with a tracking number is saved.
  # Retry logic lives in MarketingSources::YardiSourceAudit#audit_property.
  def perform(property_id)
    property = Property.find_by(id: property_id)
    return if property.nil?

    MarketingSources::YardiSourceAudit.new.audit_property(property)
  end
end
