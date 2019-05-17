$(document).on('turbolinks:load', function() {

  function schedule_conflict_check(e){
    var scheduled_action_form = $("#scheduled_action_form");
    if (scheduled_action_form[0] == undefined) return(true);

    var form_attrs = scheduled_action_form.serialize();
      $.ajax({
        type: 'GET',
        url: '/scheduled_actions/conflict_check.json',
        data: form_attrs,
        dataType: 'json',
      })
      .done(function(data){
        if (data == true) {
          $("select[id^=scheduled_action_schedule_attributes_date]").addClass("scheduling_conflict");
          $("select[id^=scheduled_action_schedule_attributes_time]").addClass("scheduling_conflict");
          $("#schedule_conflict_message").addClass("scheduling_conflict");
        } else {
          $("select[id^=scheduled_action_schedule_attributes_date]").removeClass("scheduling_conflict");
          $("select[id^=scheduled_action_schedule_attributes_time]").removeClass("scheduling_conflict");
          $("#schedule_conflict_message").removeClass("scheduling_conflict");
        }
      })
  }

  var retry_delay_selector_container = $('.retry_delay_selector');
  retry_delay_selector_container.hide();

  var schedule_selectors = $("select[name^='scheduled_action[schedule_attributes]']");
  schedule_selectors.on('change', schedule_conflict_check);

  var scheduled_action_completion_action_selector = $('#scheduled_action_completion_action');
  scheduled_action_completion_action_selector.on('change', function(e){
    // on Mark Task as Completed selection change
    var target = e.target;
    if (e.target.value == 'retry') {
      retry_delay_selector_container.show()
    } else {
      retry_delay_selector_container.hide();
    }
  });
  schedule_conflict_check();
});
