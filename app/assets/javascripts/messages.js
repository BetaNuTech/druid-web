$(document).on('turbolinks:load', function() {

  $('#message_template_load_button').hide();

  $('#message_template_select').on('change', function(e){
    $('#message_template_load_button').show();
    $('#message_template_view_button').hide();
  });

  $('#message_template_load_button').on('click', function(){
    var selected_template_id = $('#message_template_select')[0].value;
    if (selected_template_id != "") {
      var baseurl = $('#message_template_load_button').data('baseurl');
      var template_param = "&message_template_id=" + selected_template_id;
      var url = baseurl + template_param;
      window.location = url;
    }
  });

});
