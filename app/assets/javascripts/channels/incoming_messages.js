$(document).on('turbolinks:load', function() {

  if (App.incoming_messages_channels == null) {
    // Initialize sound effect
    App.incoming_message_sound = document.createElement('audio');
    App.incoming_message_sound.setAttribute('id', 'incoming_message_notification_sound');
    App.incoming_message_sound.setAttribute('src', '/attention.mp3');
    App.incoming_message_sound.load();

    // State initialization
    App.incoming_messages_channels = [];
    App.incoming_message_queue = [];

    // Notification Timer
    setInterval(issueMessageNotification, 5000);

    // Subscribe to User Messages channel
    subscribeIncomingUserMessages(App.incoming_messages_channels);

    // Subscribe to Property Messages channels
    setSubscribedProperties();
    if (App.subscribed_properties.length == 0) {
      setTimeout(function(){
        App.subscribed_properties.forEach(function(e){ subscribeIncomingPropertyMessages(App.incoming_messages_channels, e) })
      }, 2000)
    } else {
      App.subscribed_properties.forEach(function(e){ subscribeIncomingPropertyMessages(App.incoming_messages_channels, e) })
    }

  } else {
    // NOOP
  }
});

function subscribeIncomingUserMessages(channels) {
  channels.push(
    App.cable.subscriptions.create(
      { channel: 'IncomingMessagesUserChannel'},
      {
        connected: function() { console.log('Listening for incoming User messages'); },
        received: function(message) { addMessageToMessageNotificationQueue(message); }
      }
    )
  )
  return(true);
}

function subscribeIncomingPropertyMessages(channels, property) {
  channels.push(
    App.cable.subscriptions.create(
      { channel: 'IncomingMessagesPropertyChannel', property_id: property.id},
      {
        connected: function() { console.log('Listening for incoming messages for ', property.name) },
        received: function(message) { addMessageToMessageNotificationQueue(message) }
      }
    )
  )
  return(true);
}

function issueMessageNotification() {
  var message = App.incoming_message_queue.pop();
  if (message !== undefined) {
    // Add badge to navigation if not already present
    if ($("#messages_incoming_notification")[0] == null) {
      $("#navigation_messages_menu_link").prepend('<span id="messages_incoming_notification"><span style="color: red" class="glyphicon glyphicon-warning-sign"></span></span>');
    }
    console.log(message.alert_message);
    var browser_notified = sendBrowserNotification("Bluesky", message.alert_message);
    if (browser_notified) {
      App.incoming_message_sound.load();
      App.incoming_message_sound.play().catch(function(err){console.log(err)});
    }
  } else {
    // NOOP
  }
  return(true);
}

function addMessageToMessageNotificationQueue(message) {
  var idx = {}
  for(var i=0; i<App.incoming_message_queue.length; i++) {
    var m = App.incoming_message_queue[i];
    idx[m.id] = true;
  }
  if (idx[message.id] != true) {
    App.incoming_message_queue.push(message);
  } else {
    // NOOP
  }
  return(true);
}
