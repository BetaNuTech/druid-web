//make tooltips work
var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
  return new bootstrap.Tooltip(tooltipTriggerEl)
})

//code for the "How To Make This Page Better" form to appear and disappear
$("#customer-support-link").on("click", function () {
    $("#customer-support-form").css("display", "block");
    $("#customer-support-link").css("display", "none");
});

$("#customer-support-form .close").on("click", function () {
    $("#customer-support-form").css("display", "none");
    $("#customer-support-link").css("display", "block");
});

//make boxes in the same row, the same height, where applicable
function equalHeight(group) {

    if ($(window).width() > 1399.99) {
        tallest = 0;
        group.each(function() {
        thisHeight = $(this).height();
        if(thisHeight > tallest) {
            tallest = thisHeight;
        }
        });
        group.height(tallest);
     }    
};
