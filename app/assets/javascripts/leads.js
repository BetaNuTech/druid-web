// Leads page JavaScript functionality

$(document).on('turbolinks:load', function() {
  // Quick navigation smooth scrolling
  $('.quick-nav-link').off('click.quickNav').on('click.quickNav', function(e) {
    e.preventDefault();
    var target = $(this.getAttribute('href'));
    
    if (target.length) {
      $('html, body').animate({
        scrollTop: target.offset().top - 80 // Offset for fixed headers
      }, 300, 'easeInOutQuart');
      
      // Add a subtle highlight effect to the target section
      target.addClass('section-highlight');
      setTimeout(function() {
        target.removeClass('section-highlight');
      }, 2000);
    }
  });
  
  // Make duplicate cards clickable
  $('.duplicate-card[data-lead-url]').off('click.duplicateCard').on('click.duplicateCard', function(e) {
    // Don't trigger if clicking on buttons or links
    if ($(e.target).closest('a, button').length === 0) {
      var url = $(this).data('lead-url');
      if (url) {
        window.location.href = url;
      }
    }
  });
  
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
  
  // Toggle animations for collapsible sections
  $('.toggle-button').off('click.toggle').on('click.toggle', function() {
    var $button = $(this);
    var target = $button.data('target');
    var $target = $(target);
    
    // Animate the chevron icon
    var $icon = $button.find('.glyphicon');
    if ($target.hasClass('in')) {
      $icon.removeClass('rotate-180');
    } else {
      $icon.addClass('rotate-180');
    }
  });
  
  // Mobile dropdown positioning fix
  $(document).on('shown.bs.dropdown', '#crumbs .dropdown', function() {
    if ($(window).width() <= 767) {
      var $dropdown = $(this).find('.dropdown-menu');
      var $toggle = $(this).find('.dropdown-toggle');
      var toggleOffset = $toggle.offset();
      var windowHeight = $(window).height();
      var dropdownHeight = $dropdown.outerHeight();
      
      // Calculate best position
      var topPosition = toggleOffset.top + $toggle.outerHeight() + 10;
      
      // Check if dropdown would go below viewport
      if (topPosition + dropdownHeight > windowHeight) {
        // Position above the toggle if there's more room
        var bottomPosition = windowHeight - toggleOffset.top + 10;
        if (toggleOffset.top > windowHeight / 2) {
          $dropdown.css({
            'position': 'fixed',
            'top': 'auto',
            'bottom': bottomPosition + 'px',
            'left': '10px',
            'right': '10px'
          });
        } else {
          // Still position below but ensure it fits
          $dropdown.css({
            'position': 'fixed',
            'top': topPosition + 'px',
            'bottom': 'auto',
            'left': '10px',
            'right': '10px',
            'max-height': (windowHeight - topPosition - 10) + 'px'
          });
        }
      } else {
        // Normal positioning below
        $dropdown.css({
          'position': 'fixed',
          'top': topPosition + 'px',
          'bottom': 'auto',
          'left': '10px',
          'right': '10px'
        });
      }
    }
  });
});