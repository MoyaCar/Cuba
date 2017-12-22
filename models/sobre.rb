require_relative 'motor'

class Sobre < ActiveRecord::Base
  belongs_to :cliente, inverse_of: :sobres

  # Registros de Sobres sin sobre físico
  scope :no_montados, ->{ where estado: 'no_montado' }
  # Sobres con sobre físico cargado
  scope :montados, ->{ where estado: 'montado' }
  # Sobres entregados al cliente
  scope :entregados, ->{ where estado: 'entregado' }
  # Sobres descargados por el banco
  scope :descargados, ->{ where estado: 'descargado' }

  validates :posicion,
    # El ángulo no se repite en un mismo nivel
    uniqueness: { scope: :nivel, allow_nil: true },
    numericality: { less_than: Motor::SPN, allow_nil: true }
  validates :estado,
    inclusion: { in: %w{no_montado montado entregado descargado} }

  validates :nivel,
    numericality: { less_than: Motor::LVL, allow_nil: true }
end
