$(document).on('turbolinks:load', function() {
  console.log("Scheduled actions JS loaded");
  
  // Debug all form submissions
  $(document).on('submit', 'form', function(e) {
    console.log("Form submission detected:", this.id, this.action);
  });
  
  // Handle form submission to ensure CKEDITOR data is synchronized
  $('#scheduled_action_form').on('submit', function(e) {
    console.log("Form submission triggered");
    
    // Check if form is valid
    var form = this;
    if (!form.checkValidity || !form.checkValidity()) {
      console.log("Form validation failed");
      return true; // Let browser handle validation
    }
    
    if (typeof CKEDITOR !== 'undefined' && CKEDITOR.instances["scheduled_action_notification_message"]) {
      try {
        // Update the textarea with CKEDITOR content before submission
        CKEDITOR.instances["scheduled_action_notification_message"].updateElement();
        console.log("CKEDITOR content updated");
      } catch(error) {
        console.error("Error updating CKEDITOR content:", error);
      }
    }
    
    console.log("Form data:", $(this).serialize());
    console.log("Form action:", $(this).attr('action'));
    console.log("Form method:", $(this).attr('method'));
    
    // Allow form submission to continue
    return true;
  });
  
  // Debug button click
  $('button[type="submit"]').on('click', function(e) {
    console.log("Submit button clicked");
    console.log("Button:", this);
    console.log("Form found:", $('#scheduled_action_form').length);
  });
  
  // Add a global function to test form submission
  window.testFormSubmit = function() {
    console.log("Testing form submission...");
    var form = $('#scheduled_action_form');
    console.log("Form found:", form.length);
    if (form.length > 0) {
      console.log("Submitting form programmatically");
      form.submit();
    } else {
      console.log("Form not found!");
    }
  };

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
      .fail(function(xhr, status, error){
        console.error("Conflict check failed:", error);
        // Remove conflict indicators on error to not block form submission
        $("select[id^=scheduled_action_schedule_attributes_date]").removeClass("scheduling_conflict");
        $("select[id^=scheduled_action_schedule_attributes_time]").removeClass("scheduling_conflict");
        $("#schedule_conflict_message").removeClass("scheduling_conflict");
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

  // Check if CKEDITOR is available before trying to use it
  if (typeof CKEDITOR !== 'undefined') {
    var editor = CKEDITOR.instances["scheduled_action_notification_message"];
    if (editor != undefined) {
      editor.destroy()
      CKEDITOR.replace("scheduled_action_notification_message");
    }
  }

  // Convert schedule hour select options from 24h to 12h
  var schedule_hour_select = $('#scheduled_action_schedule_attributes_time_4i')[0];
  if (schedule_hour_select != undefined) {
      rekeyHourSelect(schedule_hour_select);
  }

});

function rekeyHourSelect(el) {
    var selected_option = null;

    while (el.options.length > 0) {
      var old_option_index = el.options.length - 1;
      var old_option = el.options[old_option_index];
      if (selected_option == null && old_option.selected == true) {
        selected_option = parseInt(old_option.value)
      }
      el.remove(old_option_index);
    }

    for (i=0; i<=23; i++) {
      var new_option = [];
      if (i == 0) {
        new_option = ["12 AM", "0"]
      } else {
        if (i < 12) {
          new_option = [i + " AM", i + ""]
        } else if (i == 12 ) {
          new_option = ["12 PM", "12"]
        } else {
          new_option = [( i - 12 ) + " PM", i + ""]
        }
      }

      var option = document.createElement('option');
      option.text = new_option[0];
      option.value = new_option[1];
      option.selected = (new_option[1] == selected_option);
      el.add(option);
    }

    return(el);
}
