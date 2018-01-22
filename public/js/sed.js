// Anular doble submit y cargas/descargas con jquery-ujs:
//
//  data-disable-with="Enviando..."

$(document).ready(function() {
  // Bloquear toda la página cuando hay varias acciones posibles
  $('.bloqueador').click(function() {
    $.blockUI({ message: null })
  })
})

// Anular el menú contextual
$(document).on('contextmenu', function(event) {
  event.preventDefault()
})
