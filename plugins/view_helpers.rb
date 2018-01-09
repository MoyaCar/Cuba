# Utilidades para las vistas
module ViewHelpers
  def clase_para_nav(path)
    "btn btn-lg #{env['REQUEST_PATH'] == path ? 'btn-primary' : 'btn-default'}"
  end

  def inicio?
    env['REQUEST_PATH'] == '/'
  end

  def cantidad_de_sobres(x)
    x == 1 ? '1 sobre' : "#{x} sobres"
  end

  # Siempre está seleccionado el tipo 'DNI' ('00') por default
  def seleccionado(tipo)
    tipo == '00' ? 'selected="selected"' : nil
  end
end
