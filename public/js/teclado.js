$(document).ready(function(){
  $('.teclado').softkeys({
    target : $('.teclado').data('target'),
    layout : [
      [
        '7', '8', '9'
      ], [
        '4', '5', '6'
      ], [
        '1', '2', '3'
      ], [
        '0'
      ]
    ]
  })
})
