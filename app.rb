require 'cuba'
require 'cuba/render'
require 'erb'

require './plugins/view_helpers.rb'

Cuba.plugin Cuba::Render
Cuba.plugin ViewHelpers

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
        @mensaje = "gracias #{numero}"

        render 'inicio',
          titulo: 'Otro título de la página',
          mensaje: "gracias #{numero}",
          tipo: 'alert-info'
      end
    end
  end
end
