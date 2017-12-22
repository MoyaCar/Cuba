# La configuración de la app. Se asume un sólo registro en la BD.
class Configuracion < ActiveRecord::Base
  # Definimos la tabla por la pluralización
  self.table_name = 'configuraciones'

  validates :nombre_archivo_novedades,
    presence: true

  def self.config
    # Buscamos la última configuración guardada. Si no hubiera, inicializamos
    # una con los valores default
    Configuracion.order(:created_at).first || Configuracion.new
  end

  def self.nombre_archivo_novedades
    config.nombre_archivo_novedades
  end

  # Archivo de configuración de entorno
  def self.entorno
    YAML::load(IO.read('config.yml'))
  end

  def self.path_archivo_novedades
    File.join entorno['csv']['path'], nombre_archivo_novedades
  end
end
