require_relative '../boot'

puts 'Cargando datos de prueba...'

un_admin = Usuario.create dni: 20000000, nombre: 'Juan Salvo', codigo: 1234, admin: true

un_usuario_con_sobre = Usuario.create dni: 20100000, nombre: 'Elena', codigo: 5678
un_usuario_sin_sobre = Usuario.create dni: 20200000, nombre: 'Martita', codigo: 5678

# Más usuarios para llenarlos de sobres y fallar por el espacio
Usuario.create dni: 20300000, nombre: 'Germán', codigo: 5678
Usuario.create dni: 20400000, nombre: 'Lucas', codigo: 5678
Usuario.create dni: 20500000, nombre: 'Favalli', codigo: 5678
Usuario.create dni: 20600000, nombre: 'Polsky', codigo: 5678

un_sobre = Sobre.create angulo: 1, nivel: 1, usuario: un_usuario_con_sobre

# Configuración con valores default
config = Configuracion.create

puts "Usuarios creados: #{Usuario.count}"
puts "Sobres creados: #{Sobre.count}"
puts "Configuración cargada:"
puts "  - espera_carga: #{config.espera_carga}"
puts "  - espera_extraccion: #{config.espera_extraccion}"
puts '...carga terminada.'
