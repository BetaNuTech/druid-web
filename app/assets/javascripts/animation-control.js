// Control animations with Turbolinks
$(document).on('turbolinks:load', function() {
  // Add class to indicate Turbolinks has loaded
  $('body').addClass('turbolinks-loaded');
});

// Remove the class before cache to allow animations on back/forward
$(document).on('turbolinks:before-cache', function() {
  $('body').removeClass('turbolinks-loaded');
});

// For initial page load (not via Turbolinks)
$(document).ready(function() {
  if (!$('body').hasClass('turbolinks-loaded')) {
    // Allow animations to play on first load
    setTimeout(function() {
      $('body').addClass('turbolinks-loaded');
    }, 1000); // After animations complete
  }
});