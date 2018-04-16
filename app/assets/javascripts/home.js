// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

window.activateLoader = function() {
  $("#loader").addClass("loading")
}

window.disableLoader = function() {
  setTimeout(function() {
    $("#loader").removeClass("loading")
  }, 200)
}

$(document).on("turbolinks:click", function(){
  window.activateLoader();
});

$(document).on("turbolinks:load", function(){
  window.disableLoader();
});

