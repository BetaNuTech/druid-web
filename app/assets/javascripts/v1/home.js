// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

window.activateLoader = function() {
  window.Loader.start();
}

window.disableLoader = function() {
  window.Loader.stop();
}

$(document).on("turbolinks:click", function(){
  window.activateLoader();
});

$(document).on("turbolinks:load", function(){
  window.disableLoader();
});

