require_relative 'boot'

task :default => :migrate

desc 'Correr migraciones'
task :migrate do
  ActiveRecord::Migrator.migrate('db/migrate', ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
end

task :superadmin do
  if ENV['dni'].nil? || ENV['pass'].nil?
    puts
    puts 'Uso: '
    puts '  rake superadmin dni=12345678 pass=1234 nombre="Juan Salvo"'
    puts
  else
    Admin.create super: true, nro_documento: ENV['dni'], password: ENV['pass'], nombre: ENV['nombre']
  end
end
