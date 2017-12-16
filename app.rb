# Rutas y acciones comunes:
#
# GET     /                             - Bienvenida a la terminal
# GET     /dni                          - Ingreso del DNI del Usuario
# POST    /dni                          - Verifica el DNI y redirige a /codigo
# GET     /codigo                       - Ingreso del Código de acceso del Usuario
# POST    /codigo                       - Verifica el Código y redirige según tipo de Usuario
#
# Rutas y acciones de clientes:
#
# GET     /extraccion                   - Inicio del proceso de extracción de sobres
# POST    /extraccion                   - Completa el proceso de extracción de un Sobre
#
# Rutas y acciones de administradores:
#
# GET     /admin/sobres                 - Inicio del proceso de carga de un Sobre leyendo un DNI
# POST    /admin/sobres                 - Completa el proceso de carga de un Sobre validando los datos
# GET     /admin/usuarios               - ABM de Usuarios administradores
# GET     /admin/usuarios/nuevo         - Formulario de carga de administrador
# POST    /admin/usuarios/crear         - Cargar un administrador
# GET     /admin/usuarios/:id/editar    - Formulario de edición de administrador
# POST    /admin/usuarios/:id/editar    - Modificar un administrador
# POST    /admin/usuarios/:id/eliminar  - Eliminar un administrador
# GET     /admin/clientes               - ABM de clientes administradores
# GET     /admin/clientes/cargar        - Inicio del proceso de carga de clientes por USB
# POST    /admin/clientes/cargar        - Carga la lista de clientes desde el USB
# POST    /admin/clientes/:id/sobres    - Carga un sobre nuevo para este usuario
# GET     /admin/logs                   - Visualización de logs del sistema

Cuba.define do
  on get do
    on root do
      # Limpiamos la sesión
      session.delete(:usuario_actual_id)
      Log.usuario_actual = nil

      render 'inicio', titulo: 'Retiro automático de Tarjetas', admin: false
    end

    on 'dni' do
      render 'dni', titulo: 'Ingrese su DNI', admin: false
    end

    on 'codigo' do
      render 'codigo', titulo: 'Ingrese su Código de Acceso', admin: false
    end

    # Verificamos que exista un sobre para este usuario o redirigimos
    on 'extraccion' do
      usuario = Usuario.find session[:usuario_actual_id]

      if usuario.sobres.sin_entregar.any?
        render 'extraccion', titulo: 'Retiro de sobres', admin: false, x: usuario.sobres.sin_entregar.count
      else
        flash[:mensaje] = 'No tiene tarjetas disponibles.'
        flash[:tipo] = 'alert-danger'

        res.redirect '/'
      end
    end

    # Control de acceso de administradores para el bloque completo
    on 'admin' do
      garantizar_admin!

      # Inicio de carga de sobres
      on 'sobres' do
        # Limpiamos los datos temporales de la sesión
        session.delete(:dni)

        render 'sobres', titulo: 'Iniciar carga de Sobres', admin: true
      end

      # Confirmación de carga de sobres
      on 'confirmar' do
        usuario = Usuario.normal.where(dni: session[:dni]).take

        render 'confirmar', titulo: 'Confirmar los datos para la carga', usuario: usuario, admin: true
      end

      # Panel de configuración
      on 'panel' do
        render 'panel', titulo: 'Panel de configuración', admin: true, config: Configuracion.config
      end

      # Inicio de carga de usuarios administradores
      on 'usuarios' do
        on root do
          render 'index_usuarios', titulo: 'Administración de usuarios', admin: true, usuarios: Usuario.admin
        end

        on 'nuevo' do
          render 'nuevo_usuario', titulo: 'Carga de usuario administrador', admin: true
        end

        on ':id/editar' do |id|
          usuario = Usuario.find(id)

          render 'editar_usuario', titulo: "Editar usuario #{usuario.nombre}", usuario: usuario, admin: true
        end
      end

      # Inicio de carga de clientes
      on 'clientes' do
        on root do
          render 'index_clientes', titulo: 'Administración de clientes y sobres', admin: true, usuarios: Usuario.normal
        end

        on 'cargar' do
          render 'cargar_clientes', titulo: 'Carga de datos de clientes', admin: true
        end
      end

      on 'logs' do
        render 'index_logs', titulo: 'Logs del sistema', admin: true, logs: Log.all
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
          flash[:mensaje] = "Le damos la bienvenida #{ usuario.admin? ? 'Administrador ' : nil}#{usuario.nombre}."
          flash[:tipo] = 'alert-info'

          siguiente = usuario.admin? ? '/admin/sobres' : '/extraccion'

          # Guardamos al usuario para la siguiente solicitud
          session[:usuario_actual_id] = usuario.id
          Log.usuario_actual = usuario.id
          Log.info "Usuario logueado: #{usuario.nombre}"

          res.redirect siguiente
        else
          flash[:mensaje] = 'Hubo un error de identificación. Verifique los datos ingresados.'
          flash[:tipo] = 'alert-danger'

          res.redirect '/'
        end
      end
    end

    # Proceso de extracción de un sobre por parte de un usuario normal
    on 'extraccion' do
      usuario = Usuario.find session[:usuario_actual_id]

      # Después de un error o terminar las extracciones volvemos al inicio
      siguiente = '/'

      if usuario.sobres.sin_entregar.any?
        sobre = usuario.sobres.sin_entregar.first
        motor = Motor.new sobre.nivel, sobre.angulo

        # Se bloquea esperando la respuesta del motor?
        motor.posicionar!

        # Se bloquea esperando la respuesta del arduino
        arduino = Arduino.new(sobre.nivel)
        respuesta = arduino.extraer!

        Log.info "Respuesta del arduino: #{respuesta}"

        case respuesta
        # Si se extrajo el sobre
        when :extraccion_ok
          flash[:mensaje] = 'Gracias por utilizar la terminal.'
          flash[:tipo] = 'alert-success'

          # En vez de borrar el sobre lo marcamos como entregado
          sobre.update_attribute :entregado, true

          # Si todavía hay sobres, continuamos la extracción
          if usuario.sobres.sin_entregar.any?
            flash[:mensaje] = "Sobres restantes: #{usuario.sobres.sin_entregar.count}."
            siguiente = '/extraccion'
          end
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

      res.redirect siguiente
    end

    # Control de acceso de administradores para el bloque completo
    on 'admin' do
      garantizar_admin!

      # Recibe el DNI cargado desde el lector de código de barras por el Usuario
      # administrador
      on 'sobres' do
        on param('dni') do |dni|
          usuario = Usuario.normal.where(dni: dni).take

          # Cuando hubo algún error volvemos al inicio del administrador
          siguiente = '/admin/sobres'

          if usuario.present?
            if (motor = Motor.new).ubicaciones_libres.any?
              # Guardamos el DNI para el próximo request
              session[:dni] = dni

              # Pedimos confirmar la carga
              siguiente = '/admin/confirmar'
            else
              flash[:mensaje] = 'No hay ubicaciones libres para el sobre.'
              flash[:tipo] = 'alert-danger'
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

          Log.info "Respuesta del arduino: #{respuesta}"

          case respuesta
          when :carga_ok
            # Si se recibió el sobre
            flash[:mensaje] = 'El sobre ha sido guardado correctamente.'
            flash[:tipo] = 'alert-success'

            usuario.sobres.create nivel: nivel, angulo: angulo
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
        res.redirect '/admin/sobres'
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
          res.redirect '/admin/panel'
        end
      end

      on 'usuarios' do
        # Procesar nuevo usuario
        on 'crear' do
          on param('nombre'), param('dni'), param('codigo') do |nombre, dni, codigo|
            usuario = Usuario.create nombre: nombre, dni: dni, codigo: codigo, admin: true

            if usuario.persisted?
              flash[:mensaje] = "El usuario ha sido creado"
              flash[:tipo] = 'alert-success'
            else
              flash[:mensaje] = "No pudo crearse el usuario. #{usuario.errors.full_messages.to_sentence}"
              flash[:tipo] = 'alert-danger'
            end

            res.redirect '/admin/usuarios'
          end
        end

        on ':id' do |id|
          usuario = Usuario.find(id)

          # Técnicamente debería ser un DELETE
          on 'eliminar' do
            usuario.destroy

            if usuario.destroyed?
              flash[:mensaje] = "El usuario ha sido eliminado"
              flash[:tipo] = 'alert-success'
            else
              flash[:mensaje] = "No pudo eliminarse el usuario. #{usuario.errors.full_messages.to_sentence}"
              flash[:tipo] = 'alert-danger'
            end

            res.redirect '/admin/usuarios'
          end

          # Procesar el formulario de edit
          on 'editar' do
            on param('nombre'), param('dni'), param('codigo') do |nombre, dni, codigo|
              if usuario.update nombre: nombre, dni: dni, codigo: codigo
                flash[:mensaje] = "El usuario ha sido modificado"
                flash[:tipo] = 'alert-success'
              else
                flash[:mensaje] = "No pudo modificarse el usuario. #{usuario.errors.full_messages.to_sentence}"
                flash[:tipo] = 'alert-danger'
              end

              res.redirect '/admin/usuarios'
            end
          end
        end
      end

      on 'clientes' do
        # Carga la lista de clientes desde el USB
        on 'cargar' do
          # cargar datos del csv
          res.redirect '/admin/clientes'
        end

        # Carga un sobre nuevo para este usuario
        on ':id/cargar' do |id|
          usuario = Usuario.find id

          if usuario.present?
            motor = Motor.new
            nivel, angulo = motor.posicion

            # Se bloquea esperando la respuesta del motor?
            motor.posicionar!

            # Se bloquea esperando la respuesta del arduino
            respuesta = Arduino.new(nivel).cargar!

            Log.info "Respuesta del arduino: #{respuesta}"

            case respuesta
            when :carga_ok
              # Si se recibió el sobre
              flash[:mensaje] = 'El sobre ha sido guardado correctamente.'
              flash[:tipo] = 'alert-success'

              usuario.sobres.create nivel: nivel, angulo: angulo
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

          # Volvemos a la lista de clientes
          res.redirect '/admin/clientes'
        end
      end
    end
  end
end
