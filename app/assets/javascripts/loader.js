window.Loader = new Object({
  start: function() {
    console.log('starting loader')
    var loader_div = document.getElementById("grid-loader");
    var loader_html = "<div class=\"grid-loader-anim\"><div></div><div></div><div></div></div>";

    if (loader_div == undefined) {
      console.log("inserting loader element");
      loader_div = document.createElement('div');
      loader_div.setAttribute("id", "grid-loader");
      loader_div.innerHTML = loader_html;
      document.body.appendChild(loader_div);
    } else {
      console.log("loader element found");
    }

    loader_div.style.top = ( window.innerHeight / 3 ) + 'px';
    loader_div.style.left = ( window.innerWidth / 2 - 200) + 'px';
    $(loader_div).fadeIn('fast')
    return true;
  },
  stop: function() {
    console.log('stopping loader')
    var loader_div = document.getElementById("grid-loader");
    if (loader_div != undefined) {
      $(loader_div).fadeOut('fast')
    }
    return true;
  }
});
