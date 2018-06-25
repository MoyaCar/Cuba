var noInteraction;

function invocation() {
  noInteraction = window.setTimeout( 
  function() {
      window.location.replace('/')
  }, 45000);
}

invocation();

$(function() {
  // Evitar doble submit, con jquery-ujs:
  //
  //   data-disable-with="Enviando..."
  //
  // Igualmente bloqueamos toda la página cuando hay varias acciones posibles
  $('.bloqueador').click(function() {
    $.blockUI({ message: null })
  })

  // Mostrar pantalla saliendo después de 20 segundos sin interacción del cliente
  if ($(".volver-al-login").length > 0) {
    window.setTimeout(function() {
      window.location.replace('/saliendo')
    }, 20000)
  }

  // Volver al login después de 5 segundos sin interacción del cliente
  if ($(".saliendo").length > 0) {
    window.setTimeout(function() {
      window.location.replace('/')
    }, 10000)
  }

  // Volver al login después de 8 segundos luego de entregar el sobre o algun error
  if ($(".salir").length > 0) {
    window.setTimeout(function() {
      window.location.replace('/')
    }, 8000)
  }

  $(document).on('touchstart', function() {
    clearTimeout( noInteraction )
    invocation()
  })

  $(document).on('click', function() {
    clearTimeout( noInteraction )
    invocation()
  })
})

// Anular el menú contextual
$(document).on('contextmenu', function(event) {
  event.preventDefault()
})
