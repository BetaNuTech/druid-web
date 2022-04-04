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
      var tracking_container = $('.' + e + '_entry_container');
      var entry_input_container = $('.' + e + '_entry');
      var entry_input = entry_input_container.find('input');

      if (data[e + '_enabled'] != false) {
        tracking_container.removeClass('hidden');
        if (data[e] !== false) {
          entry_input_container.removeClass('hidden');
          if ( entry_input.val() == '') entry_input.val(data[e]);
        } else {
          entry_input_container.addClass('hidden')
        }
      } else {
        tracking_container.addClass('hidden');
        entry_input_container.addClass('hidden')
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
  // End Lead Source selection beahviors


  // Email Lead Source selection behaviors
  function applySelectMarketingSourceEmailLeadSource(data, status) {
    if ( status !== 'success' ) return(false);
    $('#email_lead_source_helpBlock').html(data['description']);
    var tracking_email_container = $('.tracking_email_container');
    var entry_container = $('.tracking_email_entry');
    var entry_input = entry_container.find('input');
    if (data['email_tracking'] != false) {
      tracking_email_container.removeClass('hidden')
    } else {
      tracking_email_container.addClass('hidden')
    }
    if (data['tracking_email'] !== false) {
      entry_container.removeClass('hidden');
      entry_input.val(data['tracking_email']);
    } else {
      entry_container.addClass('hidden')
    }
  }
  function onSelectMarketingSourceEmailLeadSource() {
    var leadsourceSelector = $('#marketing_source--email_lead_source--selector')[0];
    if (leadsourceSelector === undefined) return(false);
    var leadsourceId = leadsourceSelector.options[leadsourceSelector.selectedIndex].value;
    var propertyId = $('#lead_source_property_id')[0].value;
    var url = "/marketing_sources/form_suggest_tracking_details.json?lead_source_id=" + leadsourceId + "&property_id=" + propertyId;
    $.ajax({
      url: url,
      dataType: 'json',
      success: applySelectMarketingSourceEmailLeadSource
    });
    return;
  }
  onSelectMarketingSourceEmailLeadSource();
  $('#marketing_source--email_lead_source--selector').on('change', onSelectMarketingSourceEmailLeadSource);
  // End Email Lead Source selection beahviors

  // Phone Lead Source selection behaviors
  function applySelectMarketingSourcePhoneLeadSource(data, status) {
    if ( status !== 'success' ) return(false);
    $('#phone_lead_source_helpBlock').html(data['description']);
    var tracking_number_entry_container = $('.tracking_number_entry_container');
    var tracking_entry_container = $('.tracking_number_entry');
    var tracking_entry_input = tracking_entry_container.find('input');

    var destination_entry_container = $('.destination_number_entry');
    var destination_entry_input = destination_entry_container.find('input');

    if (data['tracking_number_enabled'] != false) {
      tracking_number_entry_container.removeClass('hidden');
    }

    if (data['tracking_number'] !== false) {
      tracking_entry_container.removeClass('hidden');
      destination_entry_container.removeClass('hidden');
      if (data['tracking_number'] != '') { tracking_entry_input.val(data['tracking_number']) }
      destination_entry_input.val(data['destination_number']);
    } else {
      tracking_entry_container.addClass('hidden');
      destination_entry_container.addClass('hidden');
    }
  }
  function onSelectMarketingSourcePhoneLeadSource() {
    var leadsourceSelector = $('#marketing_source--phone_lead_source--selector')[0];
    if (leadsourceSelector === undefined) return(false);
    var leadsourceId = leadsourceSelector.options[leadsourceSelector.selectedIndex].value;
    var propertyId = $('#lead_source_property_id')[0].value;
    var url = "/marketing_sources/form_suggest_tracking_details.json?lead_source_id=" + leadsourceId + "&property_id=" + propertyId;
    $.ajax({
      url: url,
      dataType: 'json',
      success: applySelectMarketingSourcePhoneLeadSource
    });
    return;
  }
  onSelectMarketingSourcePhoneLeadSource();
  $('#marketing_source--phone_lead_source--selector').on('change', onSelectMarketingSourcePhoneLeadSource);
  // End Phone Lead Source selection beahviors

  $('.marketing_source_marketing_expense_row').mouseover(function(e){
    $(e.target).find('a').removeClass('hidden');
  })
});

