# Utilidades para las vistas
module ViewHelpers
  def clase_para_nav(path)
    @ruta == path ? 'active' : 'inactive' 
  end
end
