// https://github.com/cozyt/softkey/blob/79c80ff2b602d3759e3b789ab636cff2f4104088/index.html
var layoutTeclado = [
  [
    '7', '8', '9'
  ], [
    '4', '5', '6'
  ], [
    '1', '2', '3'
  ], [
    '0', 'delete'
  ]
]

// El div donde inicializar el teclado virtual
var elemento = '<div class="teclado"></div>'
// El elemento de 'teclado' actual
var teclado = null

$(document).on('focus', 'input.enfocable', function() {
  $(teclado).remove()

  $('.teclado-contenedor').append(elemento)

  teclado = $('.teclado').softkeys({
    target : $(this).data('target'),
    layout : layoutTeclado
  })
})
