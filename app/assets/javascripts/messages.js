// Messages page JavaScript functionality

$(document).on('turbolinks:load', function() {
  // Auto-submit filters when toggled
  $('.filter-toggle input[type="checkbox"]').on('change', function() {
    // Optional: Auto-submit the form when a filter is toggled
    // Uncomment the line below if you want instant filtering
    // $('#messages-filter-form').submit();
  });
  
  // Make message cards clickable
  $(document).on('click', '.message-list-card', function(e) {
    // Don't navigate if clicking on buttons or links
    if ($(e.target).closest('.btn, .lead-link, a').length === 0) {
      var url = $(this).data('url');
      if (url) {
        window.location.href = url;
      }
    }
  });
  
  // Prevent action buttons from bubbling up
  $(document).on('click', '.message-list-card .btn', function(e) {
    e.stopPropagation();
  });
  
  // Prevent lead links from bubbling up
  $(document).on('click', '.message-list-card .lead-link', function(e) {
    e.stopPropagation();
  });
  
  // Mark as read AJAX handling
  $(document).on('ajax:success', '[id^="message-read-button-"]', function(e) {
    var messageId = $(this).attr('id').replace('message-read-button-', '');
    var card = $('#message-preview-' + messageId);
    
    // Remove unread class and badge
    card.removeClass('unread');
    card.find('.status-unread').fadeOut(300, function() {
      $(this).remove();
    });
    
    // Hide the button
    $(this).fadeOut(300);
  });
});