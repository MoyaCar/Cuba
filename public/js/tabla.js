$(document).ready(function(){
  $('.data-table').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 7,
    lengthChange: false,
    columns: [
      null,
      null,
      { orderable: false }
    ],
    dom:
      "<'row'<'col-sm-6'l><'col-sm-6'>>" +
      "<'row'<'col-sm-12'tr>>" +
      "<'row'<'col-sm-12'p>>" +
      "<'row'<'col-sm-12'i>>"
  });

  $('.data-table-logs').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 7,
    lengthChange: false,
    dom:
      "<'row'<'col-sm-6'l><'col-sm-6'>>" +
      "<'row'<'col-sm-12'tr>>" +
      "<'row'<'col-sm-12'p>>" +
      "<'row'<'col-sm-12'i>>"
  });

  $('.data-table-clientes').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 7,
    lengthChange: false,
    columns: [
      null,
      null,
      null,
      null,
      { orderable: false }
    ],
    dom:
      "<'row'<'col-sm-6'l><'col-sm-6'>>" +
      "<'row'<'col-sm-12'tr>>" +
      "<'row'<'col-sm-12'p>>" +
      "<'row'<'col-sm-12'i>>"
  });
});

$(document).on('input', 'input.filtro', function () {
  $('.data-table, .data-table-clientes').DataTable().search(this.value).draw();
});
