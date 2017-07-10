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

      render 'inicio', titulo: 'El título de la página'
    end

    on 'dni' do
      render 'dni', titulo: 'Ingrese su DNI'
    end

    on 'codigo' do
      render 'codigo', titulo: 'Ingrese su Código de Acceso'
    end

    on 'carga' do
      render 'carga', titulo: 'Acerque el sobre al lector'
    end

    # Verificamos que exista un sobre para este usuario o redirigimos
    on 'extraccion' do
      usuario = Usuario.find session[:usuario_actual_id]

      if usuario.sobre.present?
        render 'extraccion', titulo: 'Retire el sobre'
      else
        flash[:mensaje] = 'No tiene un sobre a su nombre en el sistema'
        flash[:tipo] = 'alert-danger'

        res.redirect '/'
      end
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
          flash[:mensaje] = "Le damos la bienvenida #{usuario.nombre}."
          flash[:tipo] = 'alert-info'

          siguiente = usuario.admin? ? '/carga' : '/extraccion'

          # Guardamos al usuario para la siguiente solicitud
          session[:usuario_actual_id] = usuario.id

          res.redirect siguiente
        else
          flash[:mensaje] = 'Hubo un error de identificación.'
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

        if usuario.present?
          if usuario.sobre.present?
            flash[:mensaje] = 'Ya hay un sobre cargado para este DNI.'
            flash[:tipo] = 'alert-danger'
          else
            if (motor = Motor.new).ubicaciones_libres.any?
              nivel, angulo = motor.posicion

              # Se bloquea esperando la respuesta del motor?
              motor.posicionar!

              # Se bloquea esperando la respuesta del arduino
              respuesta = Arduino.new(nivel).cargar!

              # Si se recibió el sobre
              if respuesta == 'ok'
                flash[:mensaje] = 'El sobre ha sido guardado correctamente.'
                flash[:tipo] = 'alert-success'

                usuario.create_sobre nivel: nivel, angulo: angulo
              else
                flash[:mensaje] = 'El sobre no ha sido guardado.'
                flash[:tipo] = 'alert-info'
              end
            else
              flash[:mensaje] = 'No hay ubicaciones libres para el sobre.'
              flash[:tipo] = 'alert-danger'
            end
          end
        else
          flash[:mensaje] = 'No hay un usuario cargado para este DNI.'
          flash[:tipo] = 'alert-danger'
        end

        # Siempre volvemos al inicio del administrador
        res.redirect '/carga'
      end
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

        # Si se extrajo el sobre
        if respuesta == 'ok'
          flash[:mensaje] = 'Gracias por utilizar la terminal.'
          flash[:tipo] = 'alert-success'

          sobre.destroy
        else
          # FIXME Habría que revisar de nuevo esta respuesta?
          arduino.cargar!

          flash[:mensaje] = 'El sobre ha sido guardado nuevamente.'
          flash[:tipo] = 'alert-info'
        end
      else
        flash[:mensaje] = 'No tiene un sobre a su nombre en el sistema'
        flash[:tipo] = 'alert-danger'
      end

      # Siempre volvemos al inicio
      res.redirect '/'
    end
  end
end
