class Sobre < ActiveRecord::Base
  belongs_to :cliente, inverse_of: :sobres

  scope :entregado, ->{ where entregado: true }
  scope :sin_entregar, ->{ where entregado: false }

  validates :posicion,
    # El ángulo no se repite en un mismo nivel
    uniqueness: { scope: :nivel },
    numericality: { less_than: Motor::SPN }

  validates :nivel,
    numericality: { less_than: Motor::LVL }
end
