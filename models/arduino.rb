class Arduino
  DIRECCIONES = {
    1 => 0x08,
    2 => 0x09
  }

  COMANDOS = {
    carga: 0x00,
    extraccion: 0x01
  }

  RESPUESTAS = {
    0x00 => :extraccion_ok,
    0x01 => :extraccion_error,
    0x02 => :carga_ok,
    0x03 => :carga_error,
    0x04 => :no_hay_carta,
    0x05 => :atascamiento # FIXME necesario?
  }

  attr_reader :dispositivo, :estado

  def initialize(nivel, opciones_mock = {})
    driver = I2CDevice::Driver::I2CDev.new('/dev/i2c-1')
    @dispositivo = I2CDevice.new(address: DIRECCIONES[nivel], driver: driver)
  rescue Exception
    # Mock de i2c por si no estamos corriendo la aplicación en la Raspberry
    Struct.new('Mock', :direccion, :respuesta) do
      def i2cset(comando)
        @comando = comando
        puts "#{comando} enviado a #{direccion}"
      end

      def i2cget(param, long)
        sleep 5
        mensaje = respuesta || (@comando == COMANDOS[:carga] ? 0x02 : 0x00)

        puts RESPUESTAS[mensaje]

        # Devolvemos el código en string, como I2CDevice
        mensaje.chr
      end
    end

    @dispositivo = Struct::Mock.new(DIRECCIONES[nivel], opciones_mock[:respuesta])
  end

  def ordenar(comando, espera)
    # escribir
    dispositivo.i2cset(COMANDOS[comando])

    # esperar que termine el proceso de hardware
    sleep espera

    # leer
    @estado = dispositivo.i2cget(0, 1).bytes.first

    RESPUESTAS[estado]
  end

  def cargar!
    ordenar :carga, 10
  end

  def extraer!
    ordenar :extraccion, 15
  end
end
