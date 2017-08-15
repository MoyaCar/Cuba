# La definición de rutas y acciones
#
# GET  /                  - Bienvenida a la terminal
# GET  /dni               - Ingreso del DNI del Usuario
# POST /dni               - Verifica el DNI y redirige a /codigo
# GET  /codigo            - Ingreso del Código de acceso del Usuario
# POST /codigo            - Verifica el Código y redirige según tipo de Usuario
# GET  /carga             - Inicio del proceso de carga de un Sobre leyendo un DNI
# POST /carga             - Completa el proceso de carga de un Sobre validando los datos
# GET  /extraccion        - Inicio del proceso de extracción de un Sobre
# POST /extraccion        - Completa el proceso de extracción de un Sobre

Cuba.define do
  on get do
    on root do
      # Limpiamos la sesión
      session.delete(:usuario_actual_id)

      render 'inicio', titulo: 'Retiro automático de Tarjetas', admin: false
    end

    on 'dni' do
      render 'dni', titulo: 'Ingrese su DNI', admin: false
    end

    on 'codigo' do
      render 'codigo', titulo: 'Ingrese su Código de Acceso', admin: false
    end

    on 'carga' do
      # Limpiamos la sesión
      session.delete(:dni)

      render 'carga', titulo: 'Iniciar carga de Sobres', admin: true
    end

    on 'confirmar' do
      usuario = Usuario.normal.where(dni: session[:dni]).take

      render 'confirmar', titulo: 'Confirmar los datos para la carga', usuario: usuario, admin: true
    end

    # Verificamos que exista un sobre para este usuario o redirigimos
    on 'extraccion' do
      usuario = Usuario.find session[:usuario_actual_id]

      if usuario.sobre.present?
        render 'extraccion', titulo: 'Retire el sobre', admin: false
      else
        flash[:mensaje] = 'No tiene tarjetas disponibles.'
        flash[:tipo] = 'alert-danger'

        res.redirect '/'
      end
    end

    on 'panel' do
      render 'panel', titulo: 'Panel de configuración', admin: true, config: Configuracion.config
    end
  end

  on post do
    # Recibe el DNI cargado por el Usuario
    on 'dni' do
      on param('dni') do |dni|
        # Guardamos el DNI para el próximo request y le pedimos el código
        session[:dni] = dni

        res.redirect '/codigo'
      end
    end

    # Recibe el Código de acceso cargado por el Usuario
    on 'codigo' do
      on param('codigo') do |codigo|
        usuario = Usuario.where(dni: session.delete(:dni), codigo: codigo).take

        if usuario.present?
          flash[:mensaje] = "Le damos la bienvenida #{ usuario.admin? ? 'Administrador ' : nil}#{usuario.nombre}."
          flash[:tipo] = 'alert-info'

          siguiente = usuario.admin? ? '/carga' : '/extraccion'

          # Guardamos al usuario para la siguiente solicitud
          session[:usuario_actual_id] = usuario.id

          res.redirect siguiente
        else
          flash[:mensaje] = 'Hubo un error de identificación. Verifique los datos ingresados.'
          flash[:tipo] = 'alert-danger'

          res.redirect '/'
        end
      end
    end

    # Recibe el DNI cargado desde el lector de código de barras por el Usuario
    # administrador
    on 'carga' do
      on param('dni') do |dni|
        usuario = Usuario.normal.where(dni: dni).take

        # Cuando hubo algún error volvemos al inicio del administrador
        siguiente = '/carga'

        if usuario.present?
          if usuario.sobre.present?
            flash[:mensaje] = 'Ya hay un sobre cargado para este DNI.'
            flash[:tipo] = 'alert-danger'
          else
            if (motor = Motor.new).ubicaciones_libres.any?
              # Guardamos el DNI para el próximo request
              session[:dni] = dni

              # Pedimos confirmar la carga
              siguiente = '/confirmar'
            else
              flash[:mensaje] = 'No hay ubicaciones libres para el sobre.'
              flash[:tipo] = 'alert-danger'
            end
          end
        else
          flash[:mensaje] = 'El identificador no pertenece a un cliente válido.'
          flash[:tipo] = 'alert-danger'
        end

        res.redirect siguiente
      end
    end

    on 'confirmar' do
      usuario = Usuario.normal.where(dni: session[:dni]).take

      if usuario.present?
        motor = Motor.new
        nivel, angulo = motor.posicion

        # Se bloquea esperando la respuesta del motor?
        motor.posicionar!

        # Se bloquea esperando la respuesta del arduino
        respuesta = Arduino.new(nivel).cargar!

        case respuesta
        when :carga_ok
          # Si se recibió el sobre
          flash[:mensaje] = 'El sobre ha sido guardado correctamente.'
          flash[:tipo] = 'alert-success'

          usuario.create_sobre nivel: nivel, angulo: angulo
        when :carga_error
          # Si no se recibió un sobre
          flash[:mensaje] = 'El sobre no ha sido guardado.'
          flash[:tipo] = 'alert-info'

        when :error_de_bus
          flash[:mensaje] = 'Falló la conexión.'
          flash[:tipo] = 'alert-danger'
        else
          flash[:mensaje] = 'Ocurrió un error.'
          flash[:tipo] = 'alert-danger'
        end
      else
        flash[:mensaje] = 'El identificador no pertenece a un cliente válido.'
        flash[:tipo] = 'alert-danger'
      end

      # Siempre volvemos al inicio del administrador
      res.redirect '/carga'
    end

    # Proceso de extracción de un sobre por parte de un usuario normal
    on 'extraccion' do
      usuario = Usuario.find session[:usuario_actual_id]
      sobre = usuario.sobre

      if sobre.present?
        motor = Motor.new sobre.nivel, sobre.angulo

        # Se bloquea esperando la respuesta del motor?
        motor.posicionar!

        # Se bloquea esperando la respuesta del arduino
        arduino = Arduino.new(sobre.nivel)
        respuesta = arduino.extraer!

        case respuesta
        # Si se extrajo el sobre
        when :extraccion_ok
          flash[:mensaje] = 'Gracias por utilizar la terminal.'
          flash[:tipo] = 'alert-success'

          sobre.destroy
        # Si no se extrajo el sobre y el arduino lo guarda automáticamente
        when :extraccion_error
          flash[:mensaje] = 'El sobre ha sido guardado nuevamente.'
          flash[:tipo] = 'alert-info'
        # Si el arduino no encontró el sobre
        when :no_hay_carta
          flash[:mensaje] = 'No se encuentra el sobre en el dispenser.'
          flash[:tipo] = 'alert-danger'
        else
          flash[:mensaje] = 'Ocurrió un error.'
          flash[:tipo] = 'alert-danger'
        end
      else
        flash[:mensaje] = 'No tiene tarjetas disponibles.'
        flash[:tipo] = 'alert-danger'
      end

      # Siempre volvemos al inicio
      res.redirect '/'
    end

    # Recibe el DNI cargado desde el lector de código de barras por el Usuario
    # administrador
    on 'configurar' do
      on param('espera_carga'), param('espera_extraccion') do |espera_carga, espera_extraccion|
        Configuracion.config.update_attributes(
          espera_carga: espera_carga,
          espera_extraccion: espera_extraccion
        )

        flash[:mensaje] = 'Configuración actualizada.'
        flash[:tipo] = 'alert-info'

        # Siempre volvemos al inicio del administrador
        res.redirect '/panel'
      end
    end
  end
end
