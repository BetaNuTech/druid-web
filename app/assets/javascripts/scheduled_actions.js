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
  schedule_conflict_check();

  var retry_delay_selector_container = $('.retry_delay_selector');
  retry_delay_selector_container.hide();

  var schedule_selectors = $("select[name^='scheduled_action[schedule_attributes]']");
  schedule_selectors.on('change', schedule_conflict_check);

  var scheduled_action_completion_action_selector = $('#scheduled_action_completion_action');
  scheduled_action_completion_action_selector.on('change', function(e){
    // on Mark Task as Completed selection change
    if (e.target.value == 'retry') {
      retry_delay_selector_container.show()
    } else {
      retry_delay_selector_container.hide();
    }
  });

  var scheduled_action_lead_action_selector = $("select[name='scheduled_action[lead_action_id]']");
  scheduled_action_lead_action_selector.on('change', function(e){
    var scheduled_action_id = $('#scheduled_action_id').val();
    var lead_action_id = $('#scheduled_action_lead_action_id').val();
    var target_id = $('#scheduled_action_target_id').val();
    var target_type = $('#scheduled_action_target_type').val();
    var url = '/scheduled_actions/update_scheduled_action_form_on_action_change.js' +
      '?scheduled_action_id=' + scheduled_action_id +
      '&lead_action_id=' + lead_action_id +
      '&target_id=' + target_id +
      '&target_type=' + target_type;
    $.ajax({
      url: url,
      dataType: 'script',
      success: ''
    });
  })

  $('#scheduled_action_load_notification_template').on('click', function(e){
    var scheduled_action_id = $('#scheduled_action_id').val();
    var lead_action_id = $('#scheduled_action_lead_action_id').val();
    var target_id = $('#scheduled_action_target_id').val();
    var target_type = $('#scheduled_action_target_type').val();
    var message_template_id = $('#message_template_select').val();
    var schedule_date_1i = $('#scheduled_action_schedule_attributes_date_1i').val();
    var schedule_date_2i = $('#scheduled_action_schedule_attributes_date_2i').val();
    var schedule_date_3i = $('#scheduled_action_schedule_attributes_date_3i').val();
    var schedule_time_4i = $('#scheduled_action_schedule_attributes_time_4i').val();
    var schedule_time_5i = $('#scheduled_action_schedule_attributes_time_5i').val();
    var url = '/scheduled_actions/load_notification_template.js' +
      '?scheduled_action_id=' + scheduled_action_id +
      '&lead_action_id=' + lead_action_id +
      '&target_id=' + target_id +
      '&target_type=' + target_type +
      '&message_template_id=' + message_template_id +
      '&schedule_date_1i=' + schedule_date_1i +
      '&schedule_date_2i=' + schedule_date_2i +
      '&schedule_date_3i=' + schedule_date_3i +
      '&schedule_time_4i=' + schedule_time_4i +
      '&schedule_time_5i=' + schedule_time_5i;
    $.ajax({
      url: url,
      dataType: 'script',
      success: ''
    });
  })

  var editor = CKEDITOR.instances["scheduled_action_notification_message"];
  if (editor != undefined) { editor.destroy() }
  CKEDITOR.replace("scheduled_action_notification_message");

});
