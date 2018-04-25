// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).on('turbolinks:load', function() {
    $("#lead_toggle_comments_form_link").on('click', function(e){
      e.preventDefault();
      $(e.target).hide()
      $("#lead_comments_form").toggle('slide');
    })
  }
);
