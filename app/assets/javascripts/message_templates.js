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
      $("#html_editor").attr("id", "plain_editor");
      var html_editor = CKEDITOR.instances["html_editor"];
      if (html_editor != undefined) {
        html_editor.destroy();
      }
    } else {
      if (subject === sms_subject) {
        $("#message_template_subject").val("");
      }
      $("#message_template_subject_input").show('slide');
      $("#plain_editor").attr("id", "html_editor");
      CKEDITOR.replace("html_editor");
    }
  });

  $("#html_editor_toggle").on('click', toggleHTMLEditor);

});

function toggleHTMLEditor(e) {
  e.preventDefault();
  if ( $("#html_editor")[0] != undefined ) {
    $("#html_editor").attr("id", "plain_editor");
    CKEDITOR.instances["html_editor"].destroy();
  } else {
    if ( $("#plain_editor")[0] != undefined ) {
      $("#plain_editor").attr("id", "html_editor");
      CKEDITOR.replace("html_editor");
    }
  }
  return(false);
}

function resizeIframe(obj){
   obj.style.height = 0;
   obj.style.height = obj.contentWindow.document.body.scrollHeight + 20 + 'px';
}
