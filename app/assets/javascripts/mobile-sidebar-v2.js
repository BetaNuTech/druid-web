// Mobile sidebar toggle functionality for v2 design
$(document).on('turbolinks:load', function() {
  var $sidebar = $('#sidebar');
  var $body = $('body');
  var $overlay = null;
  
  // Ensure sidebar is hidden on mobile by default
  if (window.innerWidth <= 767) {
    $sidebar.removeClass('open');
  }
  
  // Function to create overlay if it doesn't exist
  function createOverlay() {
    if (!$overlay || !$overlay.length) {
      $overlay = $('<div class="sidebar-overlay"></div>');
      $body.append($overlay);
    }
    return $overlay;
  }
  
  // Function to open sidebar
  function openSidebar() {
    $sidebar.addClass('open');
    $body.addClass('sidebar-open');
    createOverlay().stop().fadeIn(200);
  }
  
  // Function to close sidebar
  function closeSidebar() {
    $sidebar.removeClass('open');
    $body.removeClass('sidebar-open');
    if ($overlay) {
      $overlay.stop().fadeOut(200, function() {
        $(this).remove();
        $overlay = null;
      });
    }
  }
  
  // Handle hamburger menu click
  $(document).on('click', '#nav-hamburger, .hamburger', function(e) {
    e.preventDefault();
    e.stopPropagation();
    
    if ($sidebar.hasClass('open')) {
      closeSidebar();
    } else {
      openSidebar();
    }
  });
  
  // Close sidebar when clicking overlay
  $(document).on('click', '.sidebar-overlay', function(e) {
    e.preventDefault();
    closeSidebar();
  });
  
  // Close sidebar when clicking a navigation link (on mobile only)
  $(document).on('click', '#sidebar a', function() {
    // Only close on mobile and not for action buttons
    if (window.innerWidth <= 767 && !$(this).closest('#sidebar--top-actions').length) {
      closeSidebar();
    }
  });
  
  // Handle window resize
  $(window).on('resize', function() {
    if (window.innerWidth > 767) {
      // Remove mobile-specific classes on desktop
      closeSidebar();
    }
  });
  
  // Handle escape key
  $(document).on('keydown', function(e) {
    if (e.key === 'Escape' && $sidebar.hasClass('open')) {
      closeSidebar();
    }
  });
});