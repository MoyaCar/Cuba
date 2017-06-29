require 'rubyserial'

class Arduino
  # Mapeo de nivel a puerto (o sea a arduino)
  PUERTOS = {
    0 => '/dev/ttyUSB0'
  }

  def initialize(nivel)
    @s = Serial.new PUERTOS[nivel]
  rescue RubySerial::Exception
    # Mock de RubySerial por si no hay raspberry conectada
    Struct.new('SerialMock', :puerto ) do
      def write(status)
        puts "#{status} enviado a #{puerto}"
      end

      def gets
        sleep 5
        puts 'ok'

        'ok'
      end
    end

    @s = Struct::SerialMock.new PUERTOS[nivel] || '/dev/null'
  end

  def activar
    @s.write 'activar'
    @s.gets
  end
end
