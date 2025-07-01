// Handle clickable cards with data-href attribute
$(document).on('turbolinks:load', function() {
  // Handle card clicks
  $(document).on('click', '.card--clickable[data-href]', function(e) {
    // Don't navigate if clicking on action buttons or links
    if ($(e.target).closest('.card__actions, a').length > 0) {
      return;
    }
    
    var href = $(this).data('href');
    if (href) {
      window.location.href = href;
    }
  });
  
  // Add hover effect for clickable cards
  $(document).on('mouseenter', '.card--clickable[data-href]', function() {
    $(this).css('cursor', 'pointer');
  });
});