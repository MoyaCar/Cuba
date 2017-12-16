require_relative '../boot'

ANGULOS = 120
pos_ini = 1
pos_med = ANGULOS/2

puts "variables creadas"

while pos_med != ANGULOS

puts "adentro del while"

m = Motor.new pos_ini,1
m.posicionar!

puts "Posicion inicial: #{pos_ini}"
puts "Posicion inicial: cargar sobre"

arduino = Arduino.new(nivel)
respuesta = arduino.cargar!
Log.logger.info "Respuesta del arduino: #{respuesta}"

puts "Posicion inicial: extrar sobre"

arduino = Arduino.new(nivel)
respuesta = arduino.extraer!
Log.logger.info "Respuesta del arduino: #{respuesta}"

pos_ini = pos_ini + 1

m = Motor.new pos_med, 1
m.posicionar!

puts "Posicion inicial: #{pos_med}"
puts "Posicion inicial: cargar sobre"

arduino = Arduino.new(nivel)
respuesta = arduino.cargar!
Log.logger.info "Respuesta del arduino: #{respuesta}"

puts "Posicion inicial: extrar sobre"

arduino = Arduino.new(nivel)
respuesta = arduino.extraer!
Log.logger.info "Respuesta del arduino: #{respuesta}"

pos_med = pos_med + 1

end
