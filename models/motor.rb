# Maneja el motor de rodete de sobres y encoder
begin
  require 'rpi_gpio'
rescue RuntimeError => e
  $log.error e.message
end

class Motor
  # Posiciones en cada nivel
  ANGULOS = 120
  NIVELES = 2

  # Pines de la Raspberry
  PULSE  = 16
  SIGN   = 18 # Sentido de giro
  SENSOR = 12 # Sensor de posición cero

  attr_reader :nivel, :angulo

  @@angulo_actual = nil

  # Inicializar una instancia de motor sin posición busca una de las libres
  def initialize(nivel = nil, angulo = nil)
    @nivel = nivel
    @angulo = angulo

    # Usamos la primer posición disponible
    # FIXME largar error si no hay
    if nivel.nil? && angulo.nil? && ubicaciones_libres.any?
      @nivel = @libres.first.first # key
      @angulo = @libres.first.last.first # values.first
    end
  end

  # Configuración de la librería y los pines
  def self.setup!
    RPi::GPIO.set_numbering :board
    RPi::GPIO.setup PULSE, as: :output, initialize: :low
    RPi::GPIO.setup SIGN, as: :output, initialize: :low
    RPi::GPIO.setup SENSOR, as: :input, pull: :up

    posicionar_en_cero!

  rescue RuntimeError => e
    $log.error e.message
  end

  # Gira hasta encontrar el sensor de posición inicial
  def self.posicionar_en_cero!
    ANGULOS.times do
      if sensor_en_cero?
        # FIXME Pasar a Configuración ?
        @@angulo_actual = 0
        break
      end

      girar!
    end

    raise 'no se encontró la posición cero' unless @@angulo_actual.present?
  end

  # Genera un mapa de ubicaciones libres en base a los sobres guardados en la
  # siguiente forma:
  #
  # {
  #   nivel: [angulo, angulo],
  #   nivel: [angulo]
  # }
  def ubicaciones_libres
    unless @libres.present?
      ubicaciones = {}

      NIVELES.times do |nivel|
        ubicaciones[nivel] = ANGULOS - Sobre.where(nivel: nivel).pluck(:angulo)
      end

      @libres = ubicaciones.reject { |_, v| v.empty? }
    end

    $log.debug { "#{@libres.values.flatten.size} ubicaciones libres" }

    @libres
  end

  def posicion
    [nivel, angulo]
  end

  # FIXME Implementar
  def posicionar!
    $log.info "Ubicando motor en posición #{posicion}"

    raise 'posición excedida' unless angulo < ANGULOS
    raise 'posición no puede ser negativa' if angulo <= 0

    media_vuelta = ANGULOS / 2

    # EJEMPLOS
    #
    # casilleros = 5
    # media_vuelta = 2 pasos
    # ángulos = [0, 1, 2, 3, 4]
    pasos = angulo - @@angulo_actual

    if pasos.positive?
      if pasos <= media_vuelta
        # angulo_actual = 2
        # angulo = 3
        # gira 1 casillero en sentido antihorario
        Motor.girar! pasos, :antihorario
      else
        # angulo_actual = 1
        # angulo = 4 (se pasa de la media vuelta)
        # gira 2 casilleros en sentido horario
        Motor.girar! ANGULOS - pasos, :horario
      end
    elsif pasos.negative?
      pasos = pasos.abs

      if pasos <= media_vuelta
        # angulo_actual = 2
        # angulo = 1
        # gira 1 casillero en sentido horario
        Motor.girar! pasos, :horario
      else
        # angulo_actual = 3
        # angulo = 0 (se pasa de la media vuelta)
        # gira 2 casilleros en sentido antihorario
        Motor.girar! ANGULOS - pasos, :antihorario
      end
    end

    # FIXME Pasar a Configuración ?
    @@angulo_actual = angulo
  end

  private

  def self.sensor_en_cero?
    RPi::GPIO.low? SENSOR
  end

  def self.girar!(pasos = 1, sentido = :antihorario)
    case sentido
    when :antihorario
      RPi::GPIO.set_low  SIGN
    when :horario
      RPi::GPIO.set_high SIGN
    else
      raise 'no tiene sentido'
    end

    pasos.times do
      RPi::GPIO.set_high PULSE

      sleep 0.01

      RPi::GPIO.set_low PULSE
    end
  end
end
