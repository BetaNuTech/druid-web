// Make table rows clickable in v2 design
$(document).on('turbolinks:load', function() {
  // Add clickable functionality to tables with data-clickable-rows
  $('table[data-clickable-rows="true"] tbody tr').each(function() {
    var $row = $(this);
    var $showLink = $row.find('a.btn--ghost:has(.glyphicon-eye-open)').first();
    
    if ($showLink.length > 0) {
      // Add clickable class and data-href
      $row.addClass('table__row--clickable');
      $row.attr('data-href', $showLink.attr('href'));
      
      // Remove the show button since row is now clickable
      $showLink.parent().remove();
    }
  });
  
  // Handle click on clickable table rows (both .table__row--clickable and .clickable)
  $(document).on('click', '.table__row--clickable, .clickable', function(e) {
    var $target = $(e.target);
    
    // Don't navigate if clicking on a button, link, or input
    if ($target.is('a, button, input, select, textarea') || 
        $target.closest('a, button, .btn, .actions').length > 0) {
      return;
    }
    
    // Navigate to the row's href
    var href = $(this).data('href');
    if (href) {
      window.location.href = href;
    }
  });
  
  // Add hover effect for clickable rows
  $(document).on('mouseenter', '.table__row--clickable, .clickable', function() {
    $(this).addClass('table__row--hover');
  });
  
  $(document).on('mouseleave', '.table__row--clickable, .clickable', function() {
    $(this).removeClass('table__row--hover');
  });
});