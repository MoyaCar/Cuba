require_relative '../boot'
require 'faker'

puts 'Cargando datos de prueba...'

# Generar nombres latinos
I18n.locale = :es
# Generar siempre los mismos datos
Faker::Config.random = Random.new(42)

# Configuración con valores default
config = Configuracion.create

5.times do
  Usuario.create admin: true,
    dni: Faker::Number.unique.between(20000000, 35000000),
    nombre: Faker::Name.unique.name,
    codigo: 1234
end

100.times do
  Usuario.create admin: false,
    dni: Faker::Number.unique.between(20000000, 35000000),
    nombre: Faker::Name.unique.name,
    codigo: 1234
end

Usuario.normal.limit(10).each do |usuario|
  motor = Motor.new
  Sobre.create usuario: usuario,
    nivel: motor.posicion.first,
    angulo: motor.posicion.last
end

puts "Usuarios creados: #{Usuario.normal.count}"
puts "Admins creados: #{Usuario.admin.count}"
puts "Sobres creados: #{Sobre.count}"
puts "Configuración cargada:"
puts "  - espera_carga: #{config.espera_carga}"
puts "  - espera_extraccion: #{config.espera_extraccion}"
puts '...carga terminada.'
