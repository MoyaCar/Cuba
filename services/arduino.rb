require 'rubyserial'

class Arduino
  # FIXME Pasar a I2C. Mapeo de nivel a puerto (o sea a arduino)
  PUERTOS = {
    1 => '/dev/ttyUSB0'
  }

  def initialize(nivel, opciones_mock = {})
    @s = Serial.new PUERTOS[nivel]
  rescue RubySerial::Exception
    # Mock de RubySerial por si no hay raspberry conectada
    Struct.new('SerialMock', :puerto, :fallar) do
      def write(status)
        puts "#{status} enviado a #{puerto}"
      end

      def gets
        sleep 5
        mensaje = fallar ? 'error' : 'ok'

        puts mensaje

        mensaje
      end
    end

    @s = Struct::SerialMock.new((PUERTOS[nivel] || '/dev/null'), opciones_mock[:fallar])
  end

  def activar!
    @s.write 'activar'
    @s.gets
  end
end
