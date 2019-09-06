
function sendBrowserNotification(title, message) {
  var notification_options = {
    body: message,
    icon: '/favicon-96x96.png'
  }

  if (!("Notification" in window)) {
    return( false );
  }

  if (Notification.permission !== "denied") {
    Notification.requestPermission();
  }

  if (Notification.permission === "granted") {
    var notification = new Notification(title, notification_options)
  } else {
    return(false);
  }

  return(true);
}

