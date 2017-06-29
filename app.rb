require 'cuba'
require 'cuba/render'
require 'cuba/flash'
require 'erb'
require 'active_record'
require 'sqlite3'
require 'yaml'

configuration = YAML::load(IO.read('db/config.yml'))
ActiveRecord::Base.establish_connection(configuration['db'])

require_relative 'plugins/view_helpers'

# Rack Middlewares
# Crear sesión para los flashes informativos
Cuba.use Rack::Session::Cookie, secret: ENV['SED_SESSION_KEY']
Cuba.use Cuba::Flash

# Cuba plugins
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
      render 'inicio', titulo: 'El título de la página'
    end

    on 'dni' do
      render 'dni', titulo: 'Ingrese su DNI'
    end
  end

  on post do
    on 'dni' do
      on param('numero') do |numero|
        sobre = Sobre.where(dni: numero).take

        if sobre.present?
          flash[:mensaje] = "gracias #{numero}"
          flash[:tipo] = 'alert-info'
        else
          flash[:mensaje] = 'error de identificación'
          flash[:tipo] = 'alert-danger'
        end

        res.redirect '/'
      end
    end
  end
end
