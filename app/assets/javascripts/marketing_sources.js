// Marketing Source Form behavior
$(document).on('turbolinks:load', function() {
  // Rate Entry selection behaviors
  function onUpdateMarketingSourceRateEntry() {
    var feeSelector = $('#marketing_source--form--fee_type--select')[0];
    if (feeSelector === undefined) return(false);
    var rateEntry = $('#marketing_source--form--fee_rate--input')[0];
    var selectedValue = feeSelector.options[feeSelector.selectedIndex].value;
    if (selectedValue === 'free') {
      rateEntry.value = '0.0';
      $(rateEntry).prop({ 'disabled': 'disabled' });
    } else {
      $(rateEntry).prop({ 'disabled': false });
    }
  }
  onUpdateMarketingSourceRateEntry();
  $('#marketing_source--form--fee_type--select').on('change', onUpdateMarketingSourceRateEntry);

  // Date Entry behaviors
  function onUpdateMarketingSourceDateEntry() {
    var activeToggle = $('#marketing_source--form--active--toggle');
    var isActive = activeToggle.is(':checked');
    if (isActive) {
      $('.marketing_source--form--start_date--select').prop({ 'disabled': false });
    } else {
      $('.marketing_source--form--start_date--select').prop({ 'disabled': 'disabled' });
    }
  }
  onUpdateMarketingSourceDateEntry();
  $('#marketing_source--form--active--toggle').on('change', onUpdateMarketingSourceDateEntry);

  // Lead Source selection behaviors
  function applySelectMarketingSourceLeadSource(data, status) {
    if ( status !== 'success' ) return(false);
    $('#lead_source_helpBlock').html(data['description']);
    ['tracking_number', 'destination_number', 'tracking_email', 'tracking_code'].forEach(function(e){
      var entry_container = $('.' + e + '_entry');
      var entry_input = entry_container.find('input');
      if (data[e] !== false) {
        entry_container.removeClass('hidden');
        if ( entry_input.val() == '') entry_input.val(data[e]);
      } else {
        entry_container.addClass('hidden')
      }
    })
  }
  function onSelectMarketingSourceLeadSource() {
    var leadsourceSelector = $('#marketing_source--lead_source--selector')[0];
    if (leadsourceSelector === undefined) return(false);
    var leadsourceId = leadsourceSelector.options[leadsourceSelector.selectedIndex].value;
    var propertyId = $('#lead_source_property_id')[0].value;
    var url = "/marketing_sources/form_suggest_tracking_details.json?lead_source_id=" + leadsourceId +
      "&property_id=" + propertyId;
    $.ajax({
      url: url,
      dataType: 'json',
      success: applySelectMarketingSourceLeadSource
    });
    return;
  }
  onSelectMarketingSourceLeadSource();
  $('#marketing_source--lead_source--selector').on('change', onSelectMarketingSourceLeadSource);

  $('.marketing_source_marketing_expense_row').mouseover(function(e){
    $(e.target).find('a').removeClass('hidden');
  })
});

