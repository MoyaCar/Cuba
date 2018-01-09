// Anular doble submit y cargas/descargas con jquery-ujs:
//
//  data-disable-with="Enviando..."

// Anular el menú contextual
$(document).on('contextmenu', function(event) {
  event.preventDefault();
});
