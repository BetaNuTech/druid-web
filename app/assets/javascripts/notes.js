// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

window.resetNoteForm = function() {
  $("#note_content").val("");
  $("#note_reason").val("");
  $("#note_action").val("");
  resetNoteScheduleForm();
}

window.resetNoteScheduleForm = function() {
  var rule_selector = $("#note_schedule_attributes_rule");
  console.log(rule_selector);
  rule_selector[0].selectedIndex = "1";
  rule_selector.change();
}

$(document).on('turbolinks:load', function() {
  $("span.toggle_note_schedule").on('click', function(e){
    $(".note_schedule_selection").slideToggle();
  });
});

