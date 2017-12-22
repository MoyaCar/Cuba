$(document).ready(function(){
  $('.data-table').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 8,
    pagingType: 'numbers',
    lengthChange: false,
    columns: [
      null,
      null,
      { orderable: false }
    ],
    dom:
      "<'row'<'col-sm-6'l><'col-sm-6'>>" +
      "<'row'<'col-sm-12'tr>>" +
      "<'row'<'col-sm-5'i><'col-sm-7'p>>"
  });

  $('.data-table-logs').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 8,
    pagingType: 'numbers',
    lengthChange: false,
    dom:
      "<'row'<'col-sm-6'l><'col-sm-6'>>" +
      "<'row'<'col-sm-12'tr>>" +
      "<'row'<'col-sm-5'i><'col-sm-7'p>>"
  });

  $('.data-table-clientes').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 8,
    pagingType: 'numbers',
    lengthChange: false,
    columns: [
      null,
      null,
      null,
      null,
      null,
      { orderable: false }
    ],
    dom:
      "<'row'<'col-sm-6'l><'col-sm-6'>>" +
      "<'row'<'col-sm-12'tr>>" +
      "<'row'<'col-sm-5'i><'col-sm-7'p>>"
  });
});

$(document).on('input', 'input.filtro', function () {
  $('.data-table, .data-table-clientes').DataTable().search(this.value).draw();
});
