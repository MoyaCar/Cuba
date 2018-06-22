# Maneja el motor de rodete de sobres
require_relative 'log'
begin
  require 'rpi_gpio'
rescue LoadError, RuntimeError => e
  Log.logger.error e.message
end

class Motor
  class CeroNoEncontrado < RuntimeError
    def codigo
      '1x01'
    end
  end

  # Variables del conjunto MOTOR+RODETE
  PPR = 4000    # Pulsos por revolucion del motor
  SPN = 120     # Sobres por nivel
  LVL = 2       # Niveles
  OFF_1 = 12    # Pulsos de offset para el nivel 1 (arriba)
  OFF_0 = 14    # Pulsos de offset para el nivel 0 (abajo)
  T_Cero = 120  # Segundos disponibles para buscar Cero

  # Variables del generador de trayectoria
  V_max = 400   # velocidad maxima [pulsos/s]
  V_min = 4     # velocidad minima [pulsos/s]
  A_max = 150   # aceleracion maxima [pulsos/s^2]
  RFA = 1       # relacion: tiempo_frenado/tiempo_aceleracion
  DT = 0.001    # paso de tiempo (1ms)

  # Pines de la Raspberry
  PULSE  = 16 # Pin de pulsos
  SIGN   = 18 # Pin de direccion
  SENSOR = 12 # Pin de sensor de posición cero

  attr_reader :nivel, :sob

  @@paso_actual = nil
  @@error = false

  # Inicializar una instancia de motor sin posición busca una de las libres
  def initialize(nivel = nil, sob = nil)
    @nivel = nivel
    @sob = sob

    Log.logger.info "Inicializando nivel: #{nivel} y sobre: #{sob}"

    # Usamos la primer posición disponible
    # FIXME largar error si no hay
    if nivel.nil? && sob.nil? && ubicaciones_libres.any?
      @nivel = @libres.first.first # key
      @sob = @libres.first.last.first # values.first
      Log.info "Posición libre encontrada: [#{@nivel}, #{@sob}]"
    end

    # Inicializar el controlador del motor si no lo hemos inicializado aún
    Motor.setup! if @@paso_actual.nil?
  end

  # Configuración de la librería y los pines
  def self.setup!
    Log.logger.info 'Configurando la librería y los pines'

    RPi::GPIO.set_numbering :board
    RPi::GPIO.setup PULSE, as: :output, initialize: :low
    RPi::GPIO.setup SIGN, as: :output, initialize: :low
    RPi::GPIO.setup SENSOR, as: :input, pull: :down

    posicionar_en_cero!
  # Capturamos nuestro error
  rescue CeroNoEncontrado => e
    Log.logger.error e.message

    # Relanzar
    raise
  # Todos los errores de RPi son RuntimeError
  rescue RuntimeError => e
    Log.logger.error e.message

    # Forzamos un 0 en development
    @@paso_actual = 0 if ENV['RACK_ENV'] == 'development'

    # Relanzamos un mensaje de cero si estamos testeando
    Motor.fallar! if ENV['SED_CERO'] == 'false'
  end

  def self.paso_actual
    @@paso_actual
  end

  # Gira hasta encontrar el sensor de posición inicial
  def self.posicionar_en_cero!
    estado_nivel_1 = Arduino.new(0).get_estado
    #estado_nivel_2 = Arduino.new(1).get_estado
    raise Arduino::Atascamiento if [estado_nivel_1, estado_nivel_2].include?(:atascamiento)
    
    Log.logger.info "Posicionando en cero"

    estado = 0
    set_sentido! :ah
    p1 = (V_max*V_max/2/A_max).to_i
    p2 = (p1*RFA).to_i
    p_act = 0
    v_act = 0
    p_aux = 0
    cont = 0

    t_inicial = Time.now
    while estado != 6 && ((t_bucle = Time.now) - t_inicial) < T_Cero
      # ACELERACION:
      if estado == 0 && p_act < p1 then # acelero
        a = A_max
      elsif estado == 0 && p_act >= p1 then # constante
        a = 0
      elsif estado == 1 && p_act < p2 then # freno
        a = -A_max / RFA
      elsif estado == 2 && p_act < p2 then # acelero volviendo
        a = A_max
      elsif estado == 2 && p_act < p2*2 then # freno volviendo
        a = -A_max / RFA
      elsif estado == 2 && p_act >= p2*2 then # despacio volviendo
        a = 0;
      elsif estado == 3 then # velocidad minima para salir del cero
        a = 0
	v_act = V_min
      elsif estado == 4 then # pulso y espera hasta salir
        pulso!
        sleep 2
      elsif estado == 5 then
        girar! 6, :ah
        estado = 2
        set_sentido! :h
        sleep 4
      end

      # PERFIL:
      v_act = v_act + a * DT
      if v_act > V_max then
        v_act = V_max
      end
      if v_act < V_min then
        v_act = V_min
      end
      p_aux = p_aux + v_act * DT

      # DISCRETIZACION A PULSO:
      if p_aux > p_act && estado < 4
        p_act = p_act + 1
        pulso!
        if estado == 3
          cont = cont + 1
        end
      end

      # DETECCION DEL SENSOR:
      if estado == 0 && sensor_en_cero? && p_act >= p1 then # comienzo a frenar
        estado = 1
        p_act = 0
	p_aux = 0
      elsif estado == 1 && (p_act >= p2 || v_act <= V_min) then # comienzo a volver (rampa)
        sleep 1.0
        estado = 2
        a = 0
        v_act = 0
        p_act = 0
        p_aux = 0
        p2 = (p2 - 5) / 2
        set_sentido! :h
      elsif estado == 2 && sensor_en_cero? then # termino de volver despacio
        estado = 3
        cont = 0
      elsif estado == 3 && sensor_en_cero? == false && cont > 5 then # ajuste final
        sleep 1.5
        set_sentido! :ah
        pulso!
        sleep 0.5
        pulso!
        set_sentido! :h
        sleep 1.5
        if sensor_en_cero? then
          estado = 4 # salgo muy despacio
        else
          estado = 5 # vuelvo algunos pasos y evaluo
        end
      elsif estado == 4 && sensor_en_cero? == false then # OK
        Log.logger.debug "Cero encontrado correctamente"
        estado = 6
	@@paso_actual = 0
      end

      sleep DT
    end

    if estado !=6  then
      mensaje = "Cero no encontrado en #{T_Cero} segundos"

      Log.logger.error mensaje
      Log.logger.info "Estado final: #{estado}"

      @@paso_actual = 0

      Motor.fallar! mensaje
    end
  end

  # Genera un mapa de ubicaciones libres en base a los sobres guardados en la
  # siguiente forma:
  #
  # {
  #   nivel: [sobre, sobre],
  #   nivel: [sobre]
  # }
  def ubicaciones_libres
    unless @libres.present?
      ubicaciones = {}

      LVL.times do |nivel|
        ubicaciones[nivel] = (0...SPN).to_a - Sobre.where(nivel: nivel).pluck(:posicion)
      end

      @libres = ubicaciones.reject { |_, v| v.empty? }
    end

    Log.logger.debug { "#{@libres.values.flatten.size} ubicaciones libres" }

    @libres
  end

  def posicion
    [nivel, sob]
  end

  def posicionar!
    estado = Arduino.new(nivel).get_estado
    raise Arduino::Atascamiento if estado == :atascamiento

    Log.logger.info "Ubicando motor en posición #{posicion}"

    raise 'posición excedida' unless sob < SPN
    raise 'posición no puede ser negativa' if sob < 0

    if nivel == 0
      pasos = (sob * PPR/SPN + OFF_0).to_i - @@paso_actual.to_i
    elsif nivel == 1
      pasos = (sob * PPR/SPN + OFF_1).to_i - @@paso_actual.to_i
    end

    Log.logger.info "Sobre: #{sob} | Paso actual: #{@@paso_actual.to_i} | Pasos: #{pasos}"

    media_vuelta = PPR / 2
    if pasos.positive?
      if pasos <= media_vuelta
        Motor.girar! pasos, :ah
      else
        Motor.girar! PPR - pasos, :h
      end
    elsif pasos.negative?
      if pasos.abs <= media_vuelta
        Motor.girar! pasos.abs, :h
      else
        Motor.girar! PPR - pasos.abs, :ah
      end
    end

    # FIXME Pasar a Configuración ?
    @@paso_actual = @@paso_actual.to_i + pasos
  end

  private

  def self.sensor_en_cero?
    RPi::GPIO.high? SENSOR
  rescue RuntimeError => e
    Log.error e.message

    # Devolver siempre 0 en development
    true
  end

  def self.set_sentido!(sentido = :h)
    case sentido
      when :h
          RPi::GPIO.set_low  SIGN
      else
          RPi::GPIO.set_high SIGN
      end
      sleep 0.00002 # 20us
  end

  def self.pulso!
    RPi::GPIO.set_high PULSE
    sleep 0.00001 # 10us
    RPi::GPIO.set_low PULSE
    sleep 0.00001 # 10us
  end

  def self.girar!(pasos = 1, sentido = :h)

    set_sentido! sentido

    p1 = (V_max*V_max/2/A_max).to_i
    p2 = (p1 * RFA).to_i

    if pasos < p1+p2
      p1 = (pasos / (1+RFA)).to_i
      p2 = pasos - p1 + 1 # frenado a V_min
    else
      p2 = p2 + 2 # frenado a V_min
    end

    p_act = 0
    v_act = 0
    p_aux = 0

    while p_act < pasos
      # ACELERACION:
      if p_act <= p1 then # acelero
        a = A_max
      elsif p_act > p1 && p_act <= pasos - p2 then # constante
        a = 0
      else # freno
        a = -A_max / RFA
      end

      # PERFIL:
      v_act = v_act + a * DT
      if v_act > V_max then
        v_act = V_max
      end
      if v_act < V_min then
        v_act = V_min
      end
      p_aux = p_aux + v_act * DT

      # DISCRETIZACION A PULSO:
      if p_aux > p_act
        p_act = p_act + 1
        pulso!
      end

      sleep DT
    end
  rescue RuntimeError => e
    Log.error e.message
  end

  def self.fallar!(mensaje = nil)
    @@error = true
    raise CeroNoEncontrado, mensaje
  end

  def self.error
    @@error
  end
end
