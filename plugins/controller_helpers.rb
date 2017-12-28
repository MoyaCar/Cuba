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

  # Chequear que no se intente acceder al sistema sin reiniciar
  def checkear_errores!
    if Motor.error || Arduino.error
      render 'error',
        admin: false,
        titulo: "Error código 0x01",
        error: "Se ha producido un error, por favor reinicie el equipo."

      res.status = 503

      halt res.finish
    end
  end
end
