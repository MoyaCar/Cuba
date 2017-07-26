# Utilidades para las vistas
module ViewHelpers
  def clase_para_nav(path)
    "btn #{env['REQUEST_PATH'] == path ? 'btn-primary' : 'btn-default'}"
  end

  def inicio?
    env['REQUEST_PATH'] == '/'
  end
end
