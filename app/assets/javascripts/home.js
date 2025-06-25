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
  
  // Make task cards clickable
  $('.task-card[data-task-url]').off('click.taskCard').on('click.taskCard', function(e) {
    // Don't trigger if clicking on buttons or links
    if ($(e.target).closest('.task-actions, a, button').length === 0) {
      var url = $(this).data('task-url');
      if (url) {
        window.location.href = url;
      }
    }
  });
});

