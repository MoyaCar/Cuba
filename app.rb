# La definición de rutas y acciones
#
# GET  /                  - Bienvenida a la terminal
# GET  /dni               - Ingreso del DNI del Usuario
# POST /dni               - Verifica el DNI y redirige a /codigo
# GET  /codigo            - Ingreso del Código de acceso del Usuario
# POST /codigo            - Verifica el Código y redirige según tipo de Usuario
# GET  /carga             - Inicio del proceso de carga de un Sobre
# GET  /extraccion        - Inicio del proceso de extracción de un Sobre

Cuba.define do
  on get do
    on root do
      LEDs.off

      render 'inicio', titulo: 'El título de la página'
    end

    on 'dni' do
      LEDs.on

      render 'dni', titulo: 'Ingrese su DNI'
    end

    on 'codigo' do
      render 'codigo', titulo: 'Ingrese su Código de Acceso'
    end

    on 'carga' do
      render 'carga', titulo: 'Acerque el sobre al Lector'
    end
  end

  on post do
    on 'dni' do
      on param('dni') do |dni|
        # Guardamos el DNI para el próximo request y le pedimos el código
        session[:dni] = dni

        res.redirect '/codigo'
      end
    end

    on 'codigo' do
      on param('codigo') do |codigo|
        usuario = Usuario.where(dni: session.delete(:dni), codigo: codigo).take

        if usuario.present?
          flash[:mensaje] = "Le damos la bienvenida #{usuario.nombre}."
          flash[:tipo] = 'alert-info'

          siguiente = usuario.admin? ? '/carga' : '/extraccion'

          res.redirect siguiente
        else
          flash[:mensaje] = 'Hubo un error de identificación.'
          flash[:tipo] = 'alert-danger'

          res.redirect '/'
        end
      end
    end

    on 'carga' do
      on param('dni') do |dni|
        usuario = Usuario.where(dni: dni).take

        if usuario.present?
          if usuario.sobre.present?
            flash[:mensaje] = 'Ya hay un sobre cargado para este DNI.'
            flash[:tipo] = 'alert-danger'

            res.redirect '/carga'
          else
            if Motor.hay_ubicaciones_libres?
              motor = Motor.new

              # TODO try-catch?
              motor.posicionar!

              nivel, angulo = motor.posicion

              # Se bloquea esperando la respuesta del arduino
              respuesta = Arduino.new(nivel).activar

              # Si se recibió el sobre
              if respuesta == 'ok'
                flash[:mensaje] = 'El sobre ha sido guardado correctamente.'
                flash[:tipo] = 'alert-success'
              else
                flash[:mensaje] = 'El sobre no ha sido guardado.'
                flash[:tipo] = 'alert-info'
              end
            else
              flash[:mensaje] = 'No hay ubicaciones libres para el sobre.'
              flash[:tipo] = 'alert-danger'

              res.redirect '/carga'
            end
          end
        else
          flash[:mensaje] = 'No hay un usuario cargado para este DNI.'
          flash[:tipo] = 'alert-danger'

          res.redirect '/carga'
        end
      end
    end
  end
end
