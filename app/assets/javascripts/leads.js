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