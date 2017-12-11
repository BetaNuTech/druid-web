module LeadSourcesHelper
  def select_supported_parsers(val)
    options_for_select(Leads::Adapters::SUPPORTED, val)
  end
end

