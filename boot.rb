require 'cuba'
require 'cuba/render'
require 'cuba/flash'
require 'erb'
require 'active_record'
require 'sqlite3'
require 'yaml'
require 'i2c'
require 'i2c/driver/i2c-dev'

# Configuración de la aplicación
configuration = YAML::load(IO.read('config.yml'))

ActiveRecord::Base.establish_connection(configuration['db'])

# Logger accesible globalmente, nivel de logueo según environment
log_level = "Logger::#{configuration['log'][ENV['RACK_ENV']] || 'DEBUG'}"
$log = Logger.new STDOUT
$log.info "Configurando Logger.level en #{log_level}"
$log.level = Object.const_get log_level

require_relative 'plugins/view_helpers'

# Rack Middlewares
# Crear sesión para los flashes informativos
Cuba.use Rack::Session::Cookie, secret: ENV['SED_SESSION_KEY']
Cuba.use Cuba::Flash

# Cuba plugins
Cuba.plugin Cuba::Render
Cuba.plugin ViewHelpers

require_relative 'plugins/view_helpers'

require_relative 'models/motor'
require_relative 'models/arduino'
require_relative 'models/usuario'
require_relative 'models/sobre'

# Servir archivos estáticos desde este directorio
Cuba.use Rack::Static, root: 'public',
  urls: ['/js', '/css', '/fonts', '/img']

# Inicializar el controlador del motor
Motor.setup!

# En app definimos rutas y controllers
require_relative 'app'
