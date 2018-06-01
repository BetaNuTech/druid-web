$(document).on("turbolinks:load", function(){
  $("#message_template_message_type").on('change', function(e){
    var selected_option_label = e.target.options[e.target.selectedIndex].label;
    if (selected_option_label == 'SMS') {
      $("#message_template_subject_input").hide('slide');
    } else {
      $("#message_template_subject_input").show('slide');
    }
  });

});
