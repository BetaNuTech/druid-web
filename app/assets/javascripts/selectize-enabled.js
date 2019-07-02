$(document).on('turbolinks:load', function() {
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
  window.enableSelectize();
});
