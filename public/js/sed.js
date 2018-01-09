// Anular doble submit y cargas/descargas con jquery-ujs:
//
//  data-disable-with="Enviando..."

// Bloquear toda la página cuando hay varias acciones posibles
$(document).ready(function() {
  $('.bloqueador').click(function() {
    $.blockUI({ message: null });
  });
});

// Anular el menú contextual
$(document).on('contextmenu', function(event) {
  event.preventDefault();
});
