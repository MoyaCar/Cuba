$(document).ready(function(){
  $('.data-table').DataTable({
    language: {
      url: '/js/datatables.es.json'
    },
    pageLength: 5,
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
});

$(document).on('input', 'input.filtro', function () {
  $('.data-table').DataTable().search(this.value).draw();
});
