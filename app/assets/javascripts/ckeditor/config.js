CKEDITOR.editorConfig = function( config )
{
  config.language = 'en';
  config.allowedContent = true;
  config.extraAllowedContent = 'div(*){*}[*]';
  config.disableNativeSpellChecker = false;

  config.toolbar_mailedit = [
    { name: 'links', items: ['Link', 'Unlink'] },
    { name: 'paragraph', groups: [ 'list', 'indent', 'align', 'bidi' ], items: [ 'NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock' ] },
    { name: 'styles', items: [ 'Font', 'FontSize' ] },
    { name: 'colors', items: [ 'TextColor', 'BGColor' ] },
    { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ], items: [ 'Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', '-', 'RemoveFormat', 'Source' ] },
  ];

  config.toolbar = "mailedit";

};

$(document).on('turbolinks:load', function() {
 if (document.getElementById('html_editor') != undefined) {
    CKEDITOR.replace('html_editor')
  }
});
