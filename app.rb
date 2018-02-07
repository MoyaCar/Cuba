# Rutas y acciones comunes:
#
# GET     /                             - Bienvenida a la terminal
# GET     /dni                          - Ingreso del DNI del Usuario
# POST    /dni                          - Verifica el DNI y redirige a /codigo
# GET     /codigo                       - Ingreso del Código de acceso del Usuario
# POST    /codigo                       - Verifica el Código y redirige según tipo de Usuario
# GET     /admin-login                  - Ingreso de Legajo y Código del Admin
# POST    /admin-login                  - Verifica Legajo y Código del Admin
#
# Rutas y acciones de clientes:
#
# GET     /extraccion                   - Inicio del proceso de extracción de sobres
# GET     /saliendo                     - Aviso de salida al cliente
# POST    /extraccion                   - Completa el proceso de extracción de un Sobre
#
# Rutas y acciones de administradores:
#
# GET     /admin/usuarios               - ABM de Usuarios administradores
# GET     /admin/usuarios/nuevo         - Formulario de carga de administrador
# POST    /admin/usuarios/crear         - Cargar un administrador
# GET     /admin/usuarios/:id/editar    - Formulario de edición de administrador
# POST    /admin/usuarios/:id/editar    - Modificar un administrador
# POST    /admin/usuarios/:id/eliminar  - Eliminar un administrador
# GET     /admin/clientes               - ABM de clientes administradores
# GET     /admin/clientes/cargar        - Inicio del proceso de carga de clientes por USB
# POST    /admin/clientes/cargar        - Carga la lista de clientes desde el USB
# GET     /admin/clientes/exportar      - Inicio del proceso de exportación al USB 
# POST    /admin/clientes/exportar      - Exporta los datos de movimientos al USB
# POST    /admin/clientes/:id/sobres    - Carga un sobre nuevo para este usuario
# GET     /admin/logs                   - Visualización de logs del sistema

Cuba.define do
  on get do
    checkear_errores!

    on root do
      # Limpiamos la sesión
      session.delete(:usuario_actual_id)
      session.delete(:usuario_actual_tipo)
      Log.usuario_actual = nil

      begin
        # Inicializar el motor y la posición cero
        unless Motor.paso_actual.present?
          Log.info "Configurando motor y buscando posición Cero"
          Motor.setup!
          Log.info "Paso actual del motor: #{Motor.paso_actual}"
          Log.info "Cero encontrado correctamente" if Motor.sensor_en_cero?
        end
      rescue Motor::CeroNoEncontrado => e
        Log.error "Cero no encontrado. Código de error #{e.codigo}."

        fallo! codigo: e.codigo
      end

      render 'inicio', titulo: 'Retirá tu tarjeta', admin: false
    end

    on 'dni' do
      render 'dni', titulo: 'Ingresa tu DNI', admin: false
    end

    on 'codigo' do
      render 'codigo', titulo: 'Ingrese su Código de Acceso', admin: false
    end

    on 'admin-login' do
      render 'admin_login', titulo: 'Ingrese su legajo y contraseña', admin: false
    end

    # Verificamos que exista un sobre para este cliente o redirigimos
    on 'extraccion' do
      cliente = Cliente.find session[:usuario_actual_id] if usuario_actual_cliente?

      if cliente.present? && cliente.sobres.montados.any?
        render 'extraccion', titulo: "Bienvenido #{cliente.nombre} Tenes #{cliente.sobres.montados.count} tarjetas para retirar", admin: false, x: cliente.sobres.montados.count
      else
        flash[:mensaje] = 'No tiene tarjetas disponibles.'
        flash[:tipo] = 'alert-danger'

        res.redirect '/'
      end
    end

    on 'saliendo' do
      render 'saliendo', titulo: 'Saliendo', admin: false
    end

    # Control de acceso de administradores para el bloque completo
    on 'admin' do
      garantizar_admin!

      # Panel de configuración
      on 'panel' do
        render 'panel', titulo: 'Panel de configuración', admin: true, config: Configuracion.config
      end

      # Inicio de carga de usuarios administradores
      on 'usuarios' do
        garantizar_superadmin!

        on root do
          render 'index_usuarios', titulo: 'Administración de usuarios', admin: true, usuarios: Admin.normal
        end

        on 'nuevo' do
          render 'nuevo_usuario', titulo: 'Carga de usuario administrador', admin: true
        end

        on ':id/editar' do |id|
          usuario = Admin.normal.find(id)

          render 'editar_usuario', titulo: "Editar usuario #{usuario.nombre}", usuario: usuario, admin: true
        end
      end

      # Inicio de carga de clientes
      on 'clientes' do
        on root do
          render 'index_clientes', titulo: 'Administración de clientes y sobres', admin: true, tarjetas: Tarjeta.all
        end

        on 'cargar' do
          render 'cargar_clientes', titulo: 'Carga de datos de clientes', admin: true
        end

        on 'exportar' do
          render 'exportar_movimientos', titulo: 'Exportar movimientos', admin: true
        end
      end

      on 'logs' do
        render 'index_logs', titulo: 'Logs del sistema', admin: true, logs: Log.all
      end
    end
  end

  on post do
    checkear_errores!

    # Recibe el DNI cargado por el Cliente
    on 'dni' do
      on param('dni'), param('tipo') do |dni, tipo|
        # Guardamos el documento para el próximo request y le pedimos el código
        session[:dni] = dni
        session[:tipo] = tipo

        res.redirect '/codigo'
      end
    end

    # Recibe el Código de acceso cargado por el Cliente
    on 'codigo' do
      on param('codigo') do |codigo|
        dni = session.delete(:dni)
        tipo = session.delete(:tipo)

        usuario = Cliente.where(nro_documento: dni, tipo_documento: tipo).take.try(:validar!, codigo)

        if usuario
          #flash[:mensaje] = "Le damos la bienvenida #{usuario.nombre}."
          #flash[:tipo] = 'alert-info'

          # Guardamos al usuario para la siguiente solicitud
          session[:usuario_actual_id] = usuario.id
          session[:usuario_actual_tipo] = usuario.class.to_s
          Log.usuario_actual = usuario
          Log.info "Usuario logueado: #{usuario.nombre}"

          res.redirect '/extraccion'
        else
          Log.error "Error de identificación, intento de ingreso de: #{dni}"
          flash[:mensaje] = 'Hubo un error de identificación. Verifique los datos ingresados.'
          flash[:tipo] = 'alert-danger'

          res.redirect '/'
        end
      end
    end

    # Recibe las credenciales (Legajo y Código) de los usuarios Admin
    on 'admin-login' do
      on param('legajo'), param('codigo') do |legajo, codigo|

        usuario = Admin.where(nro_documento: legajo).take.try(:authenticate, codigo)

        if usuario
          flash[:mensaje] = "Le damos la bienvenida Administrador #{usuario.nombre}."
          flash[:tipo] = 'alert-info'

          # Guardamos al usuario para la siguiente solicitud
          session[:usuario_actual_id] = usuario.id
          session[:usuario_actual_tipo] = usuario.class.to_s
          Log.usuario_actual = usuario
          Log.info "Usuario logueado: #{usuario.nombre}"

          res.redirect '/admin/clientes'
        else
          Log.error "Error de identificación de admin, intento de ingreso de: #{legajo}"
          flash[:mensaje] = 'Hubo un error de identificación. Verifique los datos ingresados.'
          flash[:tipo] = 'alert-danger'

          res.redirect '/'
        end
      end
    end

    # Proceso de extracción de un sobre por parte de un cliente
    on 'extraccion' do
      cliente = Cliente.find session[:usuario_actual_id] if usuario_actual_cliente?

      # Después de un error o terminar las extracciones volvemos al inicio
      siguiente = '/'

      begin
        if cliente.present? && cliente.sobres.montados.any?
          sobre = cliente.sobres.montados.first
          motor = Motor.new sobre.nivel, sobre.posicion

          motor.posicionar!

          respuesta = Arduino.new(sobre.nivel).extraer!

          Log.info "Respuesta del arduino: #{respuesta}"

          case respuesta
          # Si se extrajo el sobre
          when :extraccion_ok
            flash[:mensaje] = 'Gracias por utilizar la terminal.'
            flash[:tipo] = 'alert-success'

            Log.info "Sobre entregado a cliente #{cliente.nro_documento}"
            # En vez de borrar el sobre lo marcamos como entregado
            sobre.update_attribute :estado, 'entregado'

            # Si todavía hay sobres, continuamos la extracción
            if cliente.sobres.montados.any?
              flash[:mensaje] = "Sobres restantes: #{cliente.sobres.montados.count}."
              siguiente = '/extraccion'
            end
          # Si no se extrajo el sobre y el arduino lo guarda automáticamente
          when :extraccion_error
            Log.info "Sobre no entregado a cliente #{cliente.nro_documento}"

            flash[:mensaje] = 'El sobre ha sido guardado nuevamente.'
            flash[:tipo] = 'alert-info'
          # Si el arduino no encontró el sobre
          when :no_hay_carta
            Log.error "No se encuentra el sobre para cliente #{cliente.nro_documento} en el dispenser"

            flash[:mensaje] = 'No se encuentra el sobre en el dispenser.'
            flash[:tipo] = 'alert-danger'
          when :atascamiento
            raise Arduino::Atascamiento
          else
            flash[:mensaje] = 'Ocurrió un error.'
            flash[:tipo] = 'alert-danger'
          end
        else
          flash[:mensaje] = 'No tiene tarjetas disponibles.'
          flash[:tipo] = 'alert-danger'
        end
      rescue Arduino::Atascamiento => e
        Log.error "Arduino de nivel #{sobre.nivel} atascado. Código de error #{e.codigo}."

        fallo! codigo: e.codigo
      end

      res.redirect siguiente
    end

    # Control de acceso de administradores para el bloque completo
    on 'admin' do
      garantizar_admin!

      on 'configurar' do
        on param('nombre_archivo_novedades'), param('prefijo_nro_proveedor') do |nombre_archivo_novedades, prefijo_nro_proveedor|
          Configuracion.config.update_attributes(
            nombre_archivo_novedades: nombre_archivo_novedades,
            prefijo_nro_proveedor: prefijo_nro_proveedor
          )

          mensaje = 'Configuración actualizada.'
          Log.info mensaje
          flash[:mensaje] = mensaje
          flash[:tipo] = 'alert-info'

          # Siempre volvemos al inicio del administrador
          res.redirect '/admin/panel'
        end
      end

      on 'usuarios' do
        garantizar_superadmin!

        # Procesar nuevo usuario
        on 'crear' do
          on param('nombre'), param('nro_documento'), param('password') do |nombre, nro_documento, password|
            usuario = Admin.create nombre: nombre, nro_documento: nro_documento, password: password

            if usuario.persisted?
              mensaje = "El usuario #{nombre} ha sido creado"
              Log.info mensaje
              flash[:mensaje] = mensaje
              flash[:tipo] = 'alert-success'
            else
              mensaje = "No pudo crearse el usuario. #{usuario.errors.full_messages.to_sentence}"
              Log.error mensaje
              flash[:mensaje] = mensaje
              flash[:tipo] = 'alert-danger'
            end

            res.redirect '/admin/usuarios'
          end
        end

        on ':id' do |id|
          usuario = Admin.normal.find(id)

          # Técnicamente debería ser un DELETE
          on 'eliminar' do
            usuario.destroy

            if usuario.destroyed?
              mensaje = "El usuario #{usuario.nombre} ha sido eliminado"
              Log.info mensaje
              flash[:mensaje] = mensaje
              flash[:tipo] = 'alert-success'
            else
              mensaje = "No pudo eliminarse el usuario. #{usuario.errors.full_messages.to_sentence}"
              Log.error mensaje
              flash[:mensaje] = mensaje
              flash[:tipo] = 'alert-danger'
            end

            res.redirect '/admin/usuarios'
          end

          # Procesar el formulario de edit
          on 'editar' do
            on param('nombre'), param('nro_documento') do |nombre, nro_documento|
              # Password es opcional
              password = req.params['password']

              if usuario.update nombre: nombre, nro_documento: nro_documento, password: password
                mensaje = "El usuario #{nombre} ha sido modificado"
                Log.info mensaje
                flash[:mensaje] = mensaje
                flash[:tipo] = 'alert-success'
              else
                mensaje = "No pudo modificarse el usuario. #{usuario.errors.full_messages.to_sentence}"
                Log.error mensaje
                flash[:mensaje] = mensaje
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
          begin
            Log.info "Carga de archivo de novedades: #{Configuracion.nombre_archivo_novedades}"
            Novedad.parsear Configuracion.path_archivo_novedades
          rescue Errno::ENOENT
            mensaje = "El archivo #{Configuracion.nombre_archivo_novedades} no existe"
            Log.error mensaje
            flash[:mensaje] = mensaje
            flash[:tipo] = 'alert-danger'
          end

          res.redirect '/admin/clientes'
        end

        on 'exportar' do
          begin
            e = Exportador.new

            e.exportar!

            mensaje = "Se ha generado el archivo #{e.nombre_archivo}."
            Log.info mensaje
            flash[:mensaje] = mensaje
            flash[:tipo] = 'alert-info'
          rescue SystemCallError => e
            mensaje = "Ocurrió un error durante la exportación."
            Log.error mensaje
            Log.error e.message
            flash[:mensaje] = mensaje
            flash[:tipo] = 'alert-danger'
          end

          res.redirect '/admin/clientes'
        end


        # Carga el sobre correspondiente
        on ':id/cargar' do |id|
          sobre = Sobre.find id

          begin
            if sobre.present?
              motor = Motor.new
              nivel, posicion = motor.posicion

              motor.posicionar!

              respuesta = Arduino.new(nivel).cargar!

              Log.info "Respuesta del arduino: #{respuesta}"

              case respuesta
              when :carga_ok
                # Si se recibió el sobre
                flash[:mensaje] = 'El sobre ha sido guardado correctamente.'
                flash[:tipo] = 'alert-success'

                sobre.update nivel: nivel, posicion: posicion, estado: 'montado'
              when :carga_error
                # Si no se recibió un sobre
                flash[:mensaje] = 'El sobre no ha sido guardado.'
                flash[:tipo] = 'alert-info'

              when :error_de_bus
                flash[:mensaje] = 'Falló la conexión.'
                flash[:tipo] = 'alert-danger'
              when :atascamiento
                raise Arduino::Atascamiento
              else
                flash[:mensaje] = 'Ocurrió un error.'
                flash[:tipo] = 'alert-danger'
              end
            else
              flash[:mensaje] = 'El identificador no pertenece a un sobre válido.'
              flash[:tipo] = 'alert-danger'
            end
          rescue Arduino::Atascamiento => e
            Log.error "Arduino de nivel #{sobre.nivel} atascado. Código de error #{e.codigo}."

            fallo! codigo: e.codigo
          end

          # Volvemos a la lista de clientes
          res.redirect '/admin/clientes'
        end

        on ':id/extraer' do |id|
          sobre = Sobre.find id

          begin
            if sobre.present?
              motor = Motor.new sobre.nivel, sobre.posicion

              motor.posicionar!

              respuesta = Arduino.new(sobre.nivel).extraer!

              Log.info "Respuesta del arduino: #{respuesta}"

              case respuesta
              # Si se extrajo el sobre
              when :extraccion_ok
                flash[:mensaje] = 'El sobre ha sido descargado.'
                flash[:tipo] = 'alert-success'

                # En vez de borrar el sobre lo marcamos como entregado
                sobre.update_attribute :estado, 'descargado'
              # Si no se extrajo el sobre y el arduino lo guarda automáticamente
              when :extraccion_error
                flash[:mensaje] = 'El sobre ha sido guardado nuevamente.'
                flash[:tipo] = 'alert-info'
              # Si el arduino no encontró el sobre
              when :no_hay_carta
                flash[:mensaje] = 'No se encuentra el sobre en el dispenser.'
                flash[:tipo] = 'alert-danger'
              when :atascamiento
                raise Arduino::Atascamiento
              else
                flash[:mensaje] = 'Ocurrió un error.'
                flash[:tipo] = 'alert-danger'
              end
            else
              flash[:mensaje] = 'El identificador no pertenece a un sobre válido.'
              flash[:tipo] = 'alert-danger'
            end
          rescue Arduino::Atascamiento => e
            Log.error "Arduino de nivel #{sobre.nivel} atascado. Código de error #{e.codigo}."

            fallo! codigo: e.codigo
          end

          # Volvemos a la lista de clientes
          res.redirect '/admin/clientes'
        end
      end
    end
  end
end
