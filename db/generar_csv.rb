require 'csv'
require_relative '../boot'

puts 'Exportando csv...'

CSV.open(
  'db/datos.csv', 'w', write_headers: true,
  headers: ['nombre', 'dni', 'codigo', 'admin', 'sobres cargados']
) do |csv|
  Usuario.find_each do |u|
    csv << [u.nombre, u.dni, u.codigo, (u.admin ? 'admin' : ''), u.sobres.count]
  end
end

puts '...exportación terminada.'
