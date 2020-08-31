module MarketingSourcesHelper
  def marketing_source_fee_type_options(fee_type)
    options_for_select(MarketingSource.fee_types_for_select, fee_type)
  end

  def marketing_source_properties(property_id)
    options_for_select(MarketingSourcePolicy.new(current_user, MarketingSource).allowed_properties.map {|p| [p.name, p.id]}, property_id)
  end

  def lead_source_incoming_integration_options(lead_source_id)
    options_for_select(LeadSource.active.incoming.order(:name).all.map {|ls| [ls.name, ls.id]}, lead_source_id)
  end

  def marketing_source_incoming_integration_options(marketing_source)
    MarketingSources::IncomingIntegrationHelper.new(
      property: marketing_source.property,
      integration: marketing_source.lead_source
    ).options_for_integration
  end
end
