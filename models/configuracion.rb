# La configuración de la app. Se asume un sólo registro en la BD.
class Configuracion < ActiveRecord::Base
  # Definimos la tabla por la pluralización
  self.table_name = 'configuraciones'

  validates :espera_carga, :espera_extraccion,
    presence: true

  def self.config
    # Buscamos la última configuración guardada. Si no hubiera, inicializamos
    # una con los valores default
    Configuracion.order(:created_at).first || Configuracion.new
  end

  def self.espera_carga
    config.espera_carga
  end

  def self.espera_extraccion
    config.espera_extraccion
  end
end
