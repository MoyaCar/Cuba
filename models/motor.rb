# Maneja el motor de rodete de sobres y encoder
class Motor
  # FIXME Hasta tener el datasheet..
  ANGULOS = 1..2
  NIVELES = 1..2

  attr_reader :nivel, :angulo

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

      NIVELES.each do |nivel|
        ubicaciones[nivel] = ANGULOS.to_a - Sobre.where(nivel: nivel).pluck(:angulo)
      end

      @libres = ubicaciones.reject { |_, v| v.empty? }
    end

    $log.debug { "#{@libres.values.flatten.size} ubicaciones libres" }

    @libres
  end

  # Inicializar una instancia de motor sin posición busca una de las libres
  def initialize(nivel = nil, angulo = nil)
    @nivel = nivel
    @angulo = angulo

    # Usamos la primer posición disponible
    if nivel.nil? && angulo.nil? && ubicaciones_libres.any?
      @nivel = @libres.first.first # key
      @angulo = @libres.first.last.first # values.first
    end
  end

  def posicion
    [nivel, angulo]
  end

  # FIXME Implementar
  def posicionar!
    $log.info "Ubicando motor en posición #{posicion}"

    # Interactúa con el hardware del motor, bloquea hasta que termina el movimiento
    sleep 5
  end
end
