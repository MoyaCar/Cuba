require 'rubyserial'

class Arduino
  def initialize(puerto)
    @s = Serial.new puerto
  end

  def activar
    @s.write 'activar'
    @s.gets
  end
end

Arduinos = [Arduino.new('/dev/ttyUSB0')]
