// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).on('turbolinks:load', function() {
  $("#lead_toggle_comments_form_link").on('click', function(e){
    e.preventDefault();
    $(e.target).hide()
    $("#lead_comments_form").slideDown();
  });
  $("#lead_show_more_comments_link").on('click', function(e){
    e.preventDefault();
    var button = $(this);
    var moreComments = $("#more_comments");
    
    if (moreComments.is(":visible")) {
      moreComments.slideUp();
      button.removeClass('showing-more');
      button.html('<span class="glyphicon glyphicon-chevron-down"></span> Show ' + moreComments.find('.comment-card').length + ' More Comments');
    } else {
      moreComments.slideDown();
      button.addClass('showing-more');
      button.html('<span class="glyphicon glyphicon-chevron-up"></span> Hide Comments');
    }
  });
  $("#lead_task_toggle_completed").on('click', function(e){
    e.preventDefault();
    var button = $(this);
    var completedTasks = $(".completed-tasks");
    var toggleText = button.find('.toggle-text');
    
    if (completedTasks.is(":visible")) {
      completedTasks.slideUp();
      toggleText.text("Show Completed");
      button.removeClass('showing-completed');
    } else {
      completedTasks.slideDown();
      toggleText.text("Hide Completed");
      button.addClass('showing-completed');
    }
  });

  // Timeline toggle enhancement
  $("#timeline_toggle_button").on('shown.bs.collapse', function(e){
    var button = $(this);
    button.find('.toggle-text').text("Hide");
  });
  
  $("#timeline_toggle_button").on('hidden.bs.collapse', function(e){
    var button = $(this);
    button.find('.toggle-text').text("Show");
  });

  // Duplicate group toggle enhancement
  $('.duplicate-group .group-toggle-btn').on('shown.bs.collapse', function(e){
    $(this).attr('aria-expanded', 'true');
  });
  
  $('.duplicate-group .group-toggle-btn').on('hidden.bs.collapse', function(e){
    $(this).attr('aria-expanded', 'false');
  });

  // Clickable duplicate cards
  $(document).on('click', '.duplicate-card.clickable', function(e){
    // Don't open if clicking on a button or link
    if ($(e.target).closest('.btn, a').length) {
      return;
    }
    
    var url = $(this).data('lead-url');
    if (url) {
      window.open(url, '_blank');
    }
  });

  // Clickable task cards
  $(document).on('click', '.task-card.clickable', function(e){
    // Don't open if clicking on a button or link
    if ($(e.target).closest('.btn, a, .btn-task-action').length) {
      return;
    }
    
    var url = $(this).data('task-url');
    if (url) {
      window.location.href = url;
    }
  });

  $('#lead_toggle_change_state').on('click', function(e){
    e.preventDefault();
    if (confirm('Only change the Lead state manually if absolutely necessary. Are you sure?')) {
      $(e.target).hide();
      $('#lead_state_name').hide();
      $('#lead_force_state').show();
    }
  });

  var lead_referrable_selector = $("select[name='lead[referral]']");
  lead_referrable_selector.on('change', function(e){
    var lead_id = $('#lead_id').val();
    var referral = $('#lead_referral').val();
    var url = '/leads/' + lead_id + '/update_referrable_options.js?referral=' + referral;
    $.ajax({
      url: url,
      dataType: 'script',
      success: ''
    })
  })

  $('.lead_assignment-agent-selector').on('change', function(){
    $('.lead_assigner-pagination').hide();
  })

  $('#lead-claim-button').on('click', function(e){
    var lead_id = $(e.target).data('lead_id');
    var url = "/leads/" + lead_id + "/trigger_state_event?eventid=claim"
    window.Loader.start();
    return(true);
  });

  $('.scheduled_action-complete-button').on('click', function(e){
    if ( confirm('Are you sure you want to mark this task as completed') ) {
      window.Loader.start();
      var el = $(e.target).parent();
      var id = el.data('scheduledActionId');
      var token = $('meta[name="csrf-token"]').attr('content');
      var url = '/scheduled_actions/' + id + '/complete.js' +
        '?scheduled_action[completion_action]=complete'
      $.ajax({
        url: url,
        dataType: 'script',
        method: 'post',
        success: '',
        headers: {
          'X-CSRF-Token': token
        }
      })
    }
    return(false);
  })



});
