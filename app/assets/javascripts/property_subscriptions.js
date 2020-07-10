function setSubscribedProperties() {
  if (App.subscribed_properties === undefined) {
    App.subscribed_properties = [];
    $.ajax("/properties.json",{
      error: function(jqXHR, status, err) { },
      success: function(data) {
        App.subscribed_properties = $.map(data, function(e) { return { id: e["id"], name: e["name"] } });
      }
    })
  }
  return(true);
}
