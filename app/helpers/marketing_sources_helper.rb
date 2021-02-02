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

  def marketing_source_lead_source_options(marketing_source)
    lead_source_id_or_general = marketing_source.lead_source_id ? marketing_source.lead_source_id : (
      marketing_source.email_lead_source_id.present? || marketing_source.phone_lead_source_id.present? ? 'Phone and Email' : nil
    )
    options_for_select(MarketingSources::IncomingIntegrationHelper.lead_source_selection_options, lead_source_id_or_general)
  end

  def marketing_source_email_lead_source_options(marketing_source)
    options_for_select(MarketingSources::IncomingIntegrationHelper.lead_email_source_selection_options, marketing_source.email_lead_source_id)
  end

  def marketing_source_phone_lead_source_options(marketing_source)
    options_for_select(MarketingSources::IncomingIntegrationHelper.lead_phone_source_selection_options, marketing_source.phone_lead_source_id)
  end
end
