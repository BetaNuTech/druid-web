window.enableSelectize = function() {
  $(".selectize").selectize(
    {
      create: true,
      createOnBlur: true,
      allowEmptyOption: true,
      selectOnTab: true,
      maxItems: 1
    });

  $(".selectize-nocreate").selectize(
    {
      create: false,
      createOnBlur: false,
      allowEmptyOption: true,
      selectOnTab: true,
      maxItems: 1
    });
}

$(document).on('turbolinks:load', function() {
  enableSelectize();
});

/* Selectize added nested form fields */
$(document).on("fields_added.nested_form_fields", function(event, param){
  $(event.target).find('.selectize').selectize();
})
