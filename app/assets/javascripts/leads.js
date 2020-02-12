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
    $(e.target).hide();
    $("#more_comments").show();
  });
  $("#lead_task_toggle_completed").on('click', function(e){
    e.preventDefault();
    $(e.target).hide();
    $("tr.lead_task_completed").show();
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
    if(confirm("Are you sure you want to claim this lead?")) {
      var lead_id = $(e.target).data('lead_id');
      var url = "/leads/" + lead_id + "/trigger_state_event?eventid=claim"
      window.Loader.start();
      $.post(url);
    } else {
      e.preventDefault();
    }
    return(true);
  });
  

});
