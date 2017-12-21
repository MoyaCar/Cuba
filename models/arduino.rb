require_relative 'log'

class Arduino
  DIRECCIONES = {
    0 => 0x08,
    1 => 0x09
  }

  COMANDOS = {
    carga: 0x01,
    extraccion: 0x02,
    cero: 0x03,
    test_on: 0x04,
    test_off: 0x05
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
    Log.error 'No se pudo cargar I2CDevice'

    # Mock de i2c por si no estamos corriendo la aplicación en la Raspberry
    unless Struct::const_defined? 'Mock'
      Struct.new('Mock', :direccion, :respuesta) do
        def i2cset(comando)
          Log.info "Comando #{comando} enviado a la dirección #{direccion} del bus"

          @comando = comando
        end

        def i2cget(param, long)
          Log.info "Pedido de datos al bus"

          sleep 5
          mensaje = respuesta || (@comando == COMANDOS[:carga] ? 0x02 : 0x00)

          Log.info "Respuesta: #{RESPUESTAS[mensaje]}"

          # Devolvemos el código en string, como I2CDevice
          mensaje.chr
        end
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

    # ------------------------------------------
    # POSIBLE CAMBIO:
    #
    #   @estado = 0x10
    #   t_inicial = Time.now
    #   while estado == 0x10 && (Time.now - t_inicial) < 30
    #     sleep 1.0
    #     @estado = dispositivo.i2cget(0, 1).bytes.first
    #   end
    # ------------------------------------------

    RESPUESTAS[estado]
  rescue Errno::EREMOTEIO
    Log.error 'No se pudieron enviar datos al bus'

    :error_de_bus
  end

  def cargar!
    Log.info "Inicio de proceso de carga"

    ordenar :carga, Configuracion.espera_carga
  end

  def extraer!
    Log.info "Inicio de proceso de extracción"

    ordenar :extraccion, Configuracion.espera_extraccion
  end

  def cero!
    Log.logger.info "Llevando presentador a cero"

    ordenar :cero, 0
  end

  def test_on!
    Log.logger.info "Test ON"
    ordenar :test_on, 0
  end

  def test_off!
    Log.logger.info "Test OFF"
    ordenar :test_off,0
  end
end
