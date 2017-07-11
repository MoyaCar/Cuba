// https://github.com/cozyt/softkey/blob/79c80ff2b602d3759e3b789ab636cff2f4104088/index.html
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
        '0', 'delete'
      ]
    ]
  })
})
