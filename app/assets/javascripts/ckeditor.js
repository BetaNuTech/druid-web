CKEDITOR.editorConfig = function( config ) {
	config.toolbarGroups = [
		{ name: 'clipboard', groups: [ 'clipboard', 'undo' ] },
		{ name: 'document', groups: [ 'mode', 'document', 'doctools' ] },
		{ name: 'styles', groups: [ 'styles' ] },
		'/',
		{ name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align', 'bidi', 'paragraph' ] },
		{ name: 'forms', groups: [ 'forms' ] },
		{ name: 'colors', groups: [ 'colors' ] },
		{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
		{ name: 'links', groups: [ 'links' ] },
		{ name: 'insert', groups: [ 'insert' ] },
		{ name: 'editing', groups: [ 'find', 'selection', 'spellchecker', 'editing' ] },
		{ name: 'tools', groups: [ 'tools' ] },
		{ name: 'others', groups: [ 'others' ] },
		{ name: 'about', groups: [ 'about' ] }
	];

  config.extraAllowedContent = 'div(*){*}[*]';

	config.removeButtons = 'Form,Checkbox,TextField,Radio,Textarea,Select,Button,ImageButton,HiddenField,Source,Save,NewPage,Preview,Print,Templates,About,Maximize,ShowBlocks,SpecialChar,Flash,Table,HorizontalRule,Smiley,PageBreak,Iframe,CopyFormatting,BidiLtr,BidiRtl,Language,Anchor,Find,Replace,SelectAll,Scayt,CreateDiv';
};

$(document).on('turbolinks:load', function() {
  if (document.getElementById('html_editor') != undefined) {
    CKEDITOR.replace('html_editor')
  }
});

