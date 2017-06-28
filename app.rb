require 'cuba'
require 'cuba/render'
require 'erb'

Cuba.plugin Cuba::Render

Cuba.define do
  on get do
    on root do
      @titulo = 'El título de la página'
      @bienvenida = 'Un texto de bienvenida'

      render 'inicio'
    end
  end
end
