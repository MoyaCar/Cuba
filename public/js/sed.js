// Anular doble submit
$(document).ready(function(){
  $('form').preventDoubleSubmission();
});

// Anular el menú contextual
$(document).on('contextmenu', function (event) {
  event.preventDefault();
});
