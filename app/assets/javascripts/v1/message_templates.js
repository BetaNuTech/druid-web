$(document).on("turbolinks:load", function(){
  $("#message_template_message_type").on('change', function(e){
    var selected_option_label = e.target.options[e.target.selectedIndex].label;
    var subject = $("#message_template_subject").val();
    var sms_subject = "SMS Message"
    if (selected_option_label === 'SMS') {
      if (subject === "") {
        $("#message_template_subject").val(sms_subject);
      }
      $("#message_template_subject_input").hide('slide');
      $("#html_editor_v2").attr("id", "plain_editor");
      destroy_html_editor_v2();
    } else {
      if (subject === sms_subject) {
        $("#message_template_subject").val("");
      }
      $("#message_template_subject_input").show('slide');
      $("#plain_editor").attr("id", "html_editor_v2");
      init_html_editor_v2();
    }
  });

});

function toggleHTMLEditor(e) {
  e.preventDefault();
  if ( $("#html_editor_v2")[0] != undefined ) {
    $("#html_editor_v2").attr("id", "plain_editor");
    destroy_html_editor_v2();
  } else {
    if ( $("#plain_editor")[0] != undefined ) {
      $("#plain_editor").attr("id", "html_editor_v2");
      init_html_editor_v2();
    }
  }
  return(false);
}

function resizeIframe(obj){
   obj.style.height = 0;
   obj.style.height = obj.contentWindow.document.body.scrollHeight + 20 + 'px';
}
