$(function() {
  // Leer y remover la página actual del storage
  pagina = Number(localStorage.getItem('pagina-actual'))
  localStorage.removeItem('pagina-actual')

  $('.data-table').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 7,
    displayStart: 7 * pagina,
    pagingType: 'full_numbers',
    lengthChange: false,
    columns: [
      null,
      null,
      { orderable: false }
    ],
    dom:
      "<'row'<'col-md-6'l><'col-md-6'>>" +
      "<'row'<'col-md-12'tr>>" +
      "<'row fondo'<'col-md-12'p>>" +
      "<'row'<'col-md-12'i>>"
  })

  $('.data-table-logs').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 7,
    pagingType: 'full_numbers',
    lengthChange: false,
    dom:
      "<'row'<'col-md-6'l><'col-md-6'>>" +
      "<'row'<'col-md-12'tr>>" +
      "<'row fondo'<'col-md-12'p>" +
      "<'col-md-12'i>>"
  })

  $('.data-table-clientes').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 7,
    displayStart: 7 * pagina,
    pagingType: 'full_numbers',
    lengthChange: false,
    columns: [
      null,
      null,
      null,
      null,
      { orderable: false }
    ],
    dom:
      "<'row'<'col-md-6'l><'col-md-6'>>" +
      "<'row'<'col-md-12'tr>>" +
      "<'row fondo'<'col-md-12'p>" +
      "<'col-md-12'i>>"
  })
})

$(document).on('input', 'input.filtro', function () {
  $('.data-table, .data-table-clientes').DataTable().search(this.value).draw()
})

// Guardar la página actual después de cada acción en la tabla
$(document).on('click', '.capturar-pagina', function() {
  pagina = $('.table').DataTable().page()

  localStorage.setItem('pagina-actual', pagina)
})
