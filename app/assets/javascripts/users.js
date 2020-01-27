$(document).on('turbolinks:load', function() {

  // User Profile: Message Signature input behaviors
  $('.user_signature').prop('disabled', !$('.user_signature_enabled').prop('checked'));
  $('.user_signature_enabled').on('change', function(){
    $('.user_signature').prop('disabled', !$('.user_signature_enabled').prop('checked'));
  })
});
