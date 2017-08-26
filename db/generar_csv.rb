require 'csv'
require_relative '../boot'

CSV.open(
  'db/datos.csv', 'w', write_headers: true,
  headers: ['nombre', 'dni', 'codigo', 'admin', 'sobre cargado']
) do |csv|
  Usuario.find_each do |u|
    csv << [u.nombre, u.dni, u.codigo, (u.admin ? 'admin' : ''), (u.sobre.present? ? 'sí' : '')]
  end
end
