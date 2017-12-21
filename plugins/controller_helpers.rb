# Utilidades para los controladores
module ControllerHelpers
  def usuario_actual_admin?
    session[:usuario_actual_tipo] == 'Admin'
  end

  def usuario_actual_cliente?
    session[:usuario_actual_tipo] == 'Cliente'
  end

  def garantizar_admin!
    if usuario_actual_admin?
      usuario = Admin.find(session[:usuario_actual_id])
    else
      no_autorizado!
    end

    no_autorizado! unless usuario.admin?
  rescue ActiveRecord::RecordNotFound
    no_autorizado!
  end

  def garantizar_superadmin!
  end

  # TODO Ver por qué se limpia el flash al redirigir
  def no_autorizado!
    flash[:tipo] = 'alert-danger'
    flash[:mensaje] = 'No está autorizado a realizar esta acción.'

    res.redirect '/'
  end
end
