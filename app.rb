require 'cuba'
require 'cuba/render'
require 'erb'

Cuba.plugin Cuba::Render

# Servir archivos estáticos desde este directorio
Cuba.use Rack::Static, root: 'public',
  urls: ['/js', '/css', '/fonts']

Cuba.define do
  on get do
    on root do
      @titulo = 'El título de la página'
      @bienvenida = 'Un texto de bienvenida'

      render 'inicio'
    end
  end
end
