// Make lead cards clickable
$(document).on('turbolinks:load', function() {
  // Handle click on lead cards
  $(document).on('click', '.lead_card', function(e) {
    // Don't navigate if clicking on a link
    if ($(e.target).is('a') || $(e.target).closest('a').length) {
      return;
    }
    
    // Find the first link in the card (lead name)
    var leadLink = $(this).find('.lead a:first');
    if (leadLink.length > 0) {
      // Navigate to the lead
      window.location.href = leadLink.attr('href');
    }
  });
});