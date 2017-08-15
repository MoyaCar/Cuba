# Un sobre con su usuario y posición en el dispenser (angulo, nivel)
class Sobre < ActiveRecord::Base
  belongs_to :usuario

  validates :usuario_id,
    # Sólo un sobre por usuario
    uniqueness: true

  validates :angulo,
    # El ángulo no se repite en un mismo nivel
    uniqueness: { scope: :nivel },
    numericality: { less_than: Motor::ANGULOS }

  validates :nivel,
    numericality: { less_than: Motor::NIVELES }
end
