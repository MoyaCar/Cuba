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

      @bienvenida = 'Un texto explicativo'

      render 'inicio', titulo: 'El título de la página'
    end

    on '/dni' do
      render 'dni', titulo: 'Ingrese DNI'
    end
  end
end
