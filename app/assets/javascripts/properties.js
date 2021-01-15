// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).on('turbolinks:load', function() {

  /* Toggle Groups of Leads on properties/XXX/duplicate_leads page */
  $("table.lead_duplicates td.group_toggle span.group_toggler").on('click', function(e){
    var button = $(e.target).first();
    button.toggleClass('group_closed');
    button.toggleClass('group_open');
    button.toggleClass('glyphicon-chevron-right');
    button.toggleClass('glyphicon-chevron-down');
    $("tr.group_secondary." + button.data('lead_group')).toggle();
  });
  $("span.master_group_toggler").on('click', function(e){
    var button = $(e.target).first();
    var group_togglers = $('td.group_toggle span.group_toggler');
    if (button.hasClass('group_closed')) {
      group_togglers.removeClass('glyphicon-chevron-right');
      group_togglers.addClass('glyphicon-chevron-down');
      $('tr.group_secondary').show();
    } else {
      group_togglers.removeClass('glyphicon-chevron-down');
      group_togglers.addClass('glyphicon-chevron-right');
      $('tr.group_secondary').hide();
    }
    button.toggleClass('group_closed');
    button.toggleClass('group_open');
    button.toggleClass('glyphicon-chevron-right');
    button.toggleClass('glyphicon-chevron-down');
  });

  $('input.working_hours_toggle_closed').on('click', function(e){
    var target = e.target;
    var dow = $(target).data('weekday');
    var is_checked = $(target).is(":checked");
    var weekday_hours = $('.working_hours_' + dow);

    if (weekday_hours[0] != undefined) {
      if (is_checked) {
        weekday_hours.addClass('hidden');
        var inputs = $("div.working_hours_" + dow + " select.working_hours_input");
        inputs.each(function(_i, e){
          var previous_val = $(e).val();
          $(e).data("previous_value", previous_val) });
          inputs.val("12:00 PM");
      } else {
        var inputs = $("div.working_hours_" + dow + " select.working_hours_input");
        inputs.each(function(_i, e){ $(e).val($(e).data("previous_value")); });
        weekday_hours.removeClass('hidden');
      }
    }
  });

});
