require_relative 'app'

task :default => :migrate

desc 'Correr migraciones'
task :migrate do
  ActiveRecord::Migrator.migrate('db/migrate', ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
end
