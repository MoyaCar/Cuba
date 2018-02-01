$(function() {
  // Evitar doble submit, con jquery-ujs:
  //
  //   data-disable-with="Enviando..."
  //
  // Igualmente bloqueamos toda la página cuando hay varias acciones posibles
  $('.bloqueador').click(function() {
    $.blockUI({ message: null })
  })

  // Volver al login después de 20 segundos sin interacción del cliente
  if ($(".volver-al-login").length > 0) {
    window.setTimeout(function() {
      window.location.replace('/')
    }, 20000)
  }
})

// Anular el menú contextual
$(document).on('contextmenu', function(event) {
  event.preventDefault()
})
