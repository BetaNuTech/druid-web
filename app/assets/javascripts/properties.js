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

});
