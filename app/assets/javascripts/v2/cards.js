// Card click handler for clickable cards
$(document).on('click', '.card--clickable[data-href]', function(e) {
  // Don't navigate if clicking on a button, link, or action
  if ($(e.target).closest('a, button, .card__actions').length > 0) {
    return;
  }
  
  var href = $(this).data('href');
  if (href) {
    window.location.href = href;
  }
});