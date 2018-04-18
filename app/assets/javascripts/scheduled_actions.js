$(document).on('turbolinks:load', function() {

  var scheduled_action_completion_action_selector = $('#scheduled_action_completion_action');
  var retry_delay_selector_container = $('#retry_delay_selector_container');

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

});
