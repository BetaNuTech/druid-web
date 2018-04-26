// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).on('turbolinks:load', function() {
  $("#glyph_sample_legend_toggle").on('click', function(e){
    $("#glyph_sample_legend").slideToggle();
  });
});
