require 'cuba'
require 'cuba/render'
require 'erb'
require 'active_record'
require 'sqlite3'
require 'yaml'

configuration = YAML::load(IO.read('db/config.yml'))
ActiveRecord::Base.establish_connection(configuration['db'])

require_relative 'plugins/view_helpers'

Cuba.plugin Cuba::Render
Cuba.plugin ViewHelpers

require_relative 'plugins/view_helpers'
require_relative 'models/sobre'

# Servir archivos estáticos desde este directorio
Cuba.use Rack::Static, root: 'public',
  urls: ['/js', '/css', '/fonts', '/img']

Cuba.define do
  on get do
    on root do
      # Pasar a la vista la ruta actual para decidir cuestiones estéticas
      @ruta = '/'

      @explicacion = 'Un texto explicativo'

      render 'inicio', titulo: 'El título de la página'
    end

    on 'dni' do
      @ruta = '/dni'
      @explicacion = 'Alguna explicación'

      render 'dni', titulo: 'Ingrese su DNI'
    end
  end

  on post do
    on 'dni' do
      on param('numero') do |numero|
        sobre = Sobre.where(dni: numero).take

        if sobre.present?
          mensaje = "gracias #{numero}"
          tipo_mensaje = 'alert-info'
        else
          mensaje = "error de identificación"
          tipo_mensaje = 'alert-danger'
        end

        render 'inicio',
          titulo: 'Otro título de la página',
          mensaje: mensaje,
          tipo: tipo_mensaje
      end
    end
  end
end
