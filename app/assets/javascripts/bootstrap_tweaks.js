$(document).on('turbolinks:load', function() {
  if (window.innerWidth > 700) {
    $('a.dropdown-toggle').on('mouseover', function(e){ e.target.click() })
  }
})
