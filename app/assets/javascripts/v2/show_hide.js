function showHide(button, targetId, showHideContext) {
  console.log('Called showHide for ', targetId, showHideContext)

  // Remove 'active' class from all siblings
  Array.from(button.parentNode.children)
    .filter(child => child.dataset.showhide === showHideContext)
    .forEach(sibling => sibling.classList.remove('active'));

  // Add 'active' class to target element
  button.classList.add('active');

  // Show target element and hide other divs with the same context
  const targetElement = document.getElementById(targetId);
  document.querySelectorAll(`div[data-showHide="${showHideContext}"]`)
    .forEach(div => {
      if (div === targetElement) {
        console.log('display ', div.id)
        div.classList.remove('d-none');
      } else {
        console.log('hide ', div.id)
        div.classList.add('d-none');
      }
    });

  // Add 'active' class to the button associated with the target element, remove from others
  document.querySelectorAll(`a[data-showHide="${showHideContext}"]`)
    .forEach(anchor => {
      if (anchor.id === `${targetId}-anchor`) {
        anchor.classList.add('active');
      } else {
        anchor.classList.remove('active');
      }
    });
}

document.addEventListener('turbolinks:load', function() {
  const anchorElements = document.querySelectorAll('a[data-showHide]');

  anchorElements.forEach(function(anchor) {
    anchor.addEventListener('click', function(event) {
      event.preventDefault();
      const event_target = event.target;
      console.log(event_target)
      const showHideContext = event_target.dataset.showhide;
      const divId = event_target.id.split('-')[0];
      console.log('Calling showHide for ', divId, showHideContext);
      showHide(anchor, divId, showHideContext);
    });
    console.log('added onclick event for ', anchor.id)
  });
});

