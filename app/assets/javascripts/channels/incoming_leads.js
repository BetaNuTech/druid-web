$(document).on('turbolinks:load', function() {

  if (App.incoming_leads_channels == null) {
    // State initialization
    App.incoming_leads_channels = [];
    App.incoming_leads_last_notified = Date.now() - 100000;


    // Get list of properties to subscribe
    var properties = [];
    $.ajax("/properties.json",{
      error: function(jqXHR, status, err) { },
      success: function(data) {
        properties = $.map(data, function(e) { return { id: e["id"], name: e["name"] } });
        properties.forEach(function(e){ subscribeIncomingLeads(App.incoming_leads_channels, e) })
      }
    })

    // Initialize sound effect
    App.incoming_lead_sound = document.createElement('audio');
    App.incoming_lead_sound.setAttribute('id', 'incoming_lead_notification_sound');
    App.incoming_lead_sound.setAttribute('src', '/cha-ching.mp3');
    App.incoming_lead_sound.load();
  }
});


function subscribeIncomingLeads(channels, property) {
  channels.push(
    App.cable.subscriptions.create(
      { channel: 'IncomingLeadsChannel', property_id: property['id'] },
      {
        connected: function() { console.log("Listening for incoming Leads at", property["name"]) },
        received: function(lead){ issueIncomingLeadNotifications(lead) }
      }
    )
  );

  return(true);
}

function issueIncomingLeadNotifications(lead) {
  console.log('Incoming Lead: ', lead['id'], lead['name']);

  // Insert Lead into Unclaimed Leads listing on Dashboard
  $.ajax('/home/insert_unclaimed_lead.js?id=' + lead['id']);

  // Add badge to navigation if not already present
  if ($("#dashboard_incoming_notification")[0] == null) {
    $("#navigation_dashboard_menu_link").append('<span id="dashboard_incoming_notification"><span style="color: red" class="glyphicon glyphicon-warning-sign"></span></span>');
  }


  // Submit Browser Notification
  var seconds_since_last_notification = ( Date.now() - App.incoming_leads_last_notified ) / 1000
  if (seconds_since_last_notification > 60) {
    var notification_body = "New incoming Lead! " + lead['name'];
    sendBrowserNotification("BlueSky", notification_body);
    App.incoming_leads_last_notified = Date.now();

    App.incoming_lead_sound.load();
    App.incoming_lead_sound.play().catch(function(err){console.log(err)});
  } else {
    console.log("Skipping incoming Lead browser notification")
  }

  return(true);
}