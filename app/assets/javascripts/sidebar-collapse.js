// Sidebar section collapse functionality with localStorage persistence
$(document).on('turbolinks:load', function() {
  // Initialize collapsible sections
  function initializeSidebarCollapse() {
    // Add collapse toggle to section headers
    $('.sidebar--header').not(':empty').each(function() {
      var $header = $(this);
      var headerText = $header.text().trim().toLowerCase();
      
      // Skip empty headers
      if (!headerText) return;
      
      // Create a unique key for this section
      var sectionKey = 'sidebar-' + headerText.replace(/\s+/g, '-');
      
      // Add collapse toggle icon and make header clickable
      if (!$header.hasClass('collapsible')) {
        $header.addClass('collapsible');
        $header.prepend('<span class="collapse-icon glyphicon glyphicon-chevron-down"></span>');
        
        // Add item count
        var itemCount = $header.nextUntil('.sidebar--header').filter('.sidebar--item').length;
        if (itemCount > 0) {
          $header.append('<span class="section-count">(' + itemCount + ')</span>');
        }
        
        // Get saved state from localStorage
        var isCollapsed = localStorage.getItem(sectionKey) === 'collapsed';
        
        // Apply saved state
        if (isCollapsed) {
          $header.addClass('collapsed');
          $header.find('.collapse-icon').removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-right');
          $header.nextUntil('.sidebar--header').hide();
        }
        
        // Add click handler
        $header.on('click', function(e) {
          e.preventDefault();
          e.stopPropagation();
          
          var $this = $(this);
          var $icon = $this.find('.collapse-icon');
          var $items = $this.nextUntil('.sidebar--header');
          
          if ($this.hasClass('collapsed')) {
            // Expand
            $this.removeClass('collapsed');
            $icon.removeClass('glyphicon-chevron-right').addClass('glyphicon-chevron-down');
            $items.slideDown(200);
            localStorage.setItem(sectionKey, 'expanded');
          } else {
            // Collapse
            $this.addClass('collapsed');
            $icon.removeClass('glyphicon-chevron-down').addClass('glyphicon-chevron-right');
            $items.slideUp(200);
            localStorage.setItem(sectionKey, 'collapsed');
          }
        });
      }
    });
  }
  
  // Initialize on page load
  initializeSidebarCollapse();
  
  // Reinitialize on sidebar content changes
  $(document).on('sidebar:updated', function() {
    initializeSidebarCollapse();
  });
});