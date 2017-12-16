# Maneja el motor de rodete de sobres y encoder
begin
  require 'rpi_gpio'
rescue LoadError, RuntimeError => e
  Log.logger.error e.message
end

class Motor
  # Pulsos por revolucion del motor
  PPR = 4000

  # Offset de posicion inicial (pulsos motor)
  OFFSET = 3

  # Posiciones en cada nivel
  ANGULOS = 120
  NIVELES = 2

  # Pines de la Raspberry
  PULSE  = 16 # Pin de pulsos
  SIGN   = 18 # Pin de direccion
  SENSOR = 12 # Pin de sensor de posición cero

  attr_reader :nivel, :angulo

  @@paso_actual = nil
  @@angulo_actual = nil

  # Inicializar una instancia de motor sin posición busca una de las libres
  def initialize(nivel = nil, angulo = nil)
    @nivel = nivel
    @angulo = angulo

    Log.logger.info "Inicializando nivel: #{nivel} y angulo: #{angulo}"

    # Usamos la primer posición disponible
    # FIXME largar error si no hay
    if nivel.nil? && angulo.nil? && ubicaciones_libres.any?
      @nivel = @libres.first.first # key
      @angulo = @libres.first.last.first # values.first
      Log.info "Posición libre encontrada: [#{@nivel}, #{@angulo}]"
    end

    # Inicializar el controlador del motor si no lo hemos inicializado aún
    Motor.setup! if @@angulo_actual.nil?
  end

  # Configuración de la librería y los pines
  def self.setup!
    Log.info 'Configurando la librería y los pines'

    RPi::GPIO.set_numbering :board
    RPi::GPIO.setup PULSE, as: :output, initialize: :low
    RPi::GPIO.setup SIGN, as: :output, initialize: :low
    RPi::GPIO.setup SENSOR, as: :input, pull: :down

    posicionar_en_cero!
  rescue RuntimeError => e
    Log.error e.message

    # Forzamos un 0 en development
    @@angulo_actual = 0
  end

  # Gira hasta encontrar el sensor de posición inicial
  def self.posicionar_en_cero!
    Log.info "Posicionando en cero"

    t_min = 0.003
    t_max = 0.030
    t_del = 0.0001

    t_pul = t_max
    estado = 0

    if sensor_en_cero? # si esta en posicion lo muevo en sentido contrario
      Log.debug "Sensor Cero activado, moviendo 2 posiciones..."
      RPi::GPIO.set_low SIGN
      sleep 0.0001
      girar! 3
    end

    Log.debug "Buscando cero..."
    RPi::GPIO.set_high SIGN
    sleep 0.0001

    for i in 1..PPR * 2
      Log.debug "Estado: #{estado} // Pulso: #{t_pul}"
      if sensor_en_cero? && estado == 0 then
        estado = 1
      elsif sensor_en_cero? && estado == 2 then
        OFFSET.times do
          RPi::GPIO.set_high PULSE
          sleep 0.0001
          RPi::GPIO.set_low PULSE
          sleep t_pul
        end
        @@angulo_actual = 0
        break
      end

      RPi::GPIO.set_high PULSE
      sleep 0.0001
      RPi::GPIO.set_low PULSE
      sleep t_pul

      if estado == 0 && t_pul > t_min then # acelero
        t_pul = t_pul - t_del
      elsif estado == 1 && t_pul < t_max then # freno
        t_pul = t_pul + t_del
      elsif estado == 1 && t_pul >= t_max then # vuelvo
        sleep 0.500
        estado = 2
        RPi::GPIO.set_low SIGN
        sleep 0.0001
        t_pul = t_pul * 1.5
      end
    end

    # FIXME ?
    # raise 'no se encontró la posición cero' unless @@angulo_actual.present?
    # asumimos la posición actual como cero
    @@angulo_actual = 0
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
        ubicaciones[nivel] = (0...ANGULOS).to_a - Sobre.where(nivel: nivel).pluck(:angulo)
      end

      @libres = ubicaciones.reject { |_, v| v.empty? }
    end

    Log.logger.debug { "#{@libres.values.flatten.size} ubicaciones libres" }

    @libres
  end

  def posicion
    [nivel, angulo]
  end

  # FIXME Implementar
  def posicionar!
    Log.info "Ubicando motor en posición #{posicion}"

    raise 'posición excedida' unless angulo < ANGULOS
    raise 'posición no puede ser negativa' if angulo < 0

    media_vuelta = ANGULOS / 2

    # EJEMPLOS
    #
    # casilleros = 5
    # media_vuelta = 2 pasos
    # ángulos = [0, 1, 2, 3, 4]
    pasos = angulo - (@@angulo_actual || 0)

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
    RPi::GPIO.high? SENSOR
  rescue RuntimeError => e
    Log.error e.message

    # Devolver siempre 0 en development
    true
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

    pasos = pasos * PPR/ANGULOS
    tiempo_min = 0.003
    tiempo_max = 0.020
    tiempo_del = 0.00005
    relacion_frenado = 2

    tiempo_pul = tiempo_max
    aux = (tiempo_max - tiempo_min) / tiempo_del
    for i in 1..pasos
      puts "DEBUG: #{i} / #{pasos} / #{aux} / #{tiempo_pul}"

      RPi::GPIO.set_high PULSE
      sleep 0.0001
      RPi::GPIO.set_low PULSE
      sleep tiempo_pul

      if pasos > (1 + relacion_frenado)*aux then
        if i < aux then
          tiempo_pul = tiempo_pul - tiempo_del
        end
        if i > pasos - aux * relacion_frenado then
	  tiempo_pul = tiempo_pul + tiempo_del / relacion_frenado
	end
      else
        if i < pasos / (1 + relacion_frenado) then
          tiempo_pul = tiempo_pul - tiempo_del
        else
          tiempo_pul = tiempo_pul + tiempo_del / relacion_frenado
        end
      end
    end
  rescue RuntimeError => e
    Log.error e.message
  end
end
