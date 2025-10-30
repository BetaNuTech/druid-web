// Leads page JavaScript functionality

$(document).on('turbolinks:load', function() {
  // Toggle comment form
  $('#lead_toggle_comments_form_link').off('click.commentForm').on('click.commentForm', function(e) {
    e.preventDefault();
    var $form = $('#lead_comments_form');
    var $button = $(this);
    
    if ($form.is(':visible')) {
      // Hide form
      $form.slideUp(300);
      $button.html('<i class="glyphicon glyphicon-plus"></i> Add Comment');
    } else {
      // Show form
      $form.slideDown(300, function() {
        // Focus on the textarea
        $form.find('textarea').focus();
      });
      $button.html('<i class="glyphicon glyphicon-remove"></i> Cancel');
    }
  });
  
  // Show more comments functionality
  $('#lead_show_more_comments_link').off('click.showMore').on('click.showMore', function(e) {
    e.preventDefault();
    var $button = $(this);
    var $moreComments = $('#more_comments');

    if ($moreComments.is(':visible')) {
      $moreComments.slideUp(300);
      $button.html('<i class="glyphicon glyphicon-chevron-down"></i> Show ' + $button.data('count') + ' More Comments');
    } else {
      $moreComments.slideDown(300);
      $button.html('<i class="glyphicon glyphicon-chevron-up"></i> Show Less');
    }
  });

  // Toggle completed tasks functionality
  $('#lead_task_toggle_completed').off('click.taskToggle').on('click.taskToggle', function(e) {
    e.preventDefault();
    var $button = $(this);
    var $completedTasks = $('.completed-tasks');
    var $pendingTasks = $('.pending-tasks');

    if ($completedTasks.is(':visible')) {
      // Show pending tasks, hide completed
      $completedTasks.slideUp(300);
      $pendingTasks.slideDown(300);
      $button.find('.toggle-text').text('Show Completed');
    } else {
      // Show completed tasks, hide pending
      $pendingTasks.slideUp(300);
      $completedTasks.slideDown(300);
      $button.find('.toggle-text').text('Show Pending');
    }
  });

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
    if ($(e.target).closest('.task-actions, .btn-task-action, a, button').length === 0) {
      var url = $(this).data('task-url');
      if (url) {
        window.location.href = url;
      }
    }
  });
  
  // Make message cards clickable
  $(document).on('click', '.message-card', function(e) {
    // Don't navigate if clicking on buttons or links
    if ($(e.target).closest('.btn, .lead-link, a').length === 0) {
      var url = $(this).data('url');
      if (url) {
        window.location.href = url;
      }
    }
  });
  
  // Prevent action buttons from bubbling up
  $(document).on('click', '.message-card .btn', function(e) {
    e.stopPropagation();
  });
  
  // Prevent lead links from bubbling up
  $(document).on('click', '.message-card .lead-link', function(e) {
    e.stopPropagation();
  });
  
  // Mark as read AJAX handling
  $(document).on('ajax:success', '[id^="message-read-button-"]', function(e) {
    var messageId = $(this).attr('id').replace('message-read-button-', '');
    var card = $('#message-' + messageId);
    
    // Remove unread class and update styling
    card.removeClass('unread');
    card.find('.status-unread').fadeOut(300, function() {
      $(this).remove();
    });
    
    // Hide the button with animation
    $(this).fadeOut(300);
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
  
  // Dropdown positioning fixes
  $(document).on('shown.bs.dropdown', '#crumbs .dropdown', function() {
    var windowWidth = $(window).width();
    var $dropdown = $(this).find('.dropdown-menu');
    var $toggle = $(this).find('.dropdown-toggle');
    
    // Tablet/narrow desktop: ensure dropdown is visible when sidebar is present
    if (windowWidth >= 768 && windowWidth <= 1200) {
      var toggleOffset = $toggle.offset();
      var dropdownWidth = $dropdown.outerWidth();
      var viewportWidth = $(window).width();
      
      // Check if dropdown would be cut off on the right
      if (toggleOffset.left + dropdownWidth > viewportWidth - 20) {
        // Position from right edge instead
        $dropdown.css({
          'left': 'auto',
          'right': '0'
        });
      }
    }
    // Mobile: full-width centered dropdown
    else if (windowWidth <= 767) {
      var toggleOffset = $toggle.offset();
      var windowHeight = $(window).height();
      var dropdownHeight = $dropdown.outerHeight();
      
      // Calculate position for fixed positioning on mobile
      var topPosition = toggleOffset.top + $toggle.outerHeight() + 5;
      
      // Apply fixed positioning for mobile
      $dropdown.css({
        'top': topPosition + 'px'
      });
      
      // Check if dropdown would go below viewport
      if (topPosition + dropdownHeight > $(window).scrollTop() + windowHeight) {
        var maxHeight = $(window).scrollTop() + windowHeight - topPosition - 20;
        if (maxHeight < 200) {
          // Position above if not enough space below
          $dropdown.css({
            'top': 'auto',
            'bottom': ($(window).height() - toggleOffset.top + 5) + 'px',
            'max-height': Math.min(toggleOffset.top - $(window).scrollTop() - 20, 400) + 'px',
            'overflow-y': 'auto'
          });
        } else {
          // Add scrolling if needed
          $dropdown.css({
            'max-height': maxHeight + 'px',
            'overflow-y': 'auto'
          });
        }
      }
    }
  });
  
  // Clean up dropdown positioning on close
  $(document).on('hidden.bs.dropdown', '#crumbs .dropdown', function() {
    $(this).find('.dropdown-menu').removeAttr('style');
  });
  
  // Mobile state panel handling
  if ($(window).width() <= 767) {
    // Prevent default dropdown on mobile
    $(document).on('click', '.mobile-state-trigger', function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      // Show mobile panel instead
      $('#mobile-state-panel').addClass('mobile-state-panel--open');
      $('body').css('overflow', 'hidden'); // Prevent background scrolling
      
      return false;
    });
    
    // Close mobile panel
    $(document).on('click', '.mobile-state-panel__close, .mobile-state-panel__overlay', function() {
      $('#mobile-state-panel').removeClass('mobile-state-panel--open');
      $('body').css('overflow', ''); // Restore scrolling
    });
    
    // Close panel when option is clicked (will navigate to new page)
    $(document).on('click', '.mobile-state-panel__option', function() {
      $('#mobile-state-panel').removeClass('mobile-state-panel--open');
      $('body').css('overflow', '');
    });
  }
});