# Utilidades para las vistas
module ViewHelpers
  def clase_para_nav(path)
    env['REQUEST_PATH'] == path ? 'active' : 'inactive'
  end

  def inicio?
    env['REQUEST_PATH'] == '/'
  end
end