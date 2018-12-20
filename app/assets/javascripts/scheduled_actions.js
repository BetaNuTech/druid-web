$(document).on('turbolinks:load', function() {

  var scheduled_action_completion_action_selector = $('#scheduled_action_completion_action');
  var retry_delay_selector_container = $('.retry_delay_selector');

  retry_delay_selector_container.hide();

  scheduled_action_completion_action_selector.on('change', function(e){
    // on Mark Task as Completed selection change
    var target = e.target;
    if (e.target.value == 'retry') {
      retry_delay_selector_container.show()
    } else {
      retry_delay_selector_container.hide();
    }
  });

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
        console.log('Conflicts?: ',data);
        if (data == true) {
          console.log("Conflict Found");
          $("select[id^=scheduled_action_schedule_attributes_date]").addClass("scheduling_conflict");
          $("select[id^=scheduled_action_schedule_attributes_time]").addClass("scheduling_conflict");
          $("#schedule_conflict_message").addClass("scheduling_conflict");
        } else {
          console.log("Conflict Not Found")
          $("select[id^=scheduled_action_schedule_attributes_date]").removeClass("scheduling_conflict");
          $("select[id^=scheduled_action_schedule_attributes_time]").removeClass("scheduling_conflict");
          $("#schedule_conflict_message").removeClass("scheduling_conflict");
        }
      })
  }

  var schedule_selectors = $("select[name^='scheduled_action[schedule_attributes]'");
  schedule_selectors.on('change', schedule_conflict_check);
  schedule_conflict_check();

});
