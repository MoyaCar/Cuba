# Maneja el motor de rodete de sobres y encoder
class Motor
  # FIXME Hasta tener el datasheet..
  ANGULOS = 1..1
  NIVELES = 1..2

  attr_reader :nivel, :angulo

  def self.hay_ubicaciones_libres?
    # FIXME Sólo para la demo. Con los datos de prueba actuales permite una
    # carga antes de llenarse. 
    Sobre.count < 2
  end

  # Inicializar una instancia de motor busca una de las posiciones libres
  def initialize
    @nivel = nil 
    @angulo = nil

    NIVELES.each do |nivel|
      libres = ANGULOS - Sobre.where(nivel: nivel).pluck(:angulo)

      # Si encontramos una posición libre en este nivel, guardamos la primera y
      # salimos del loop
      if libres.any?
        @nivel = nivel
        @angulo = libres.first

        break
      end
    end
  end

  def posicion
    [@nivel, @angulo]
  end

  def posicionar!
    # Interactúa con el hardware del motor, bloquea hasta que termina el movimiento
    sleep 5
  end
end
