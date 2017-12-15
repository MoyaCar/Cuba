# Utilidades para los controladores
module ControllerHelpers
  def garantizar_admin!
    usuario = Usuario.find(session[:usuario_actual_id])
    
    no_autorizado! unless usuario.admin?
  rescue ActiveRecord::RecordNotFound
    no_autorizado!
  end

  # TODO Ver por qué se limpia el flash al redirigir
  def no_autorizado!
    flash[:tipo] = 'alert-danger'
    flash[:mensaje] = 'No está autorizado a realizar esta acción.'

    res.redirect '/'
  end
end
