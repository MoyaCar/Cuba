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
      render 'inicio', titulo: 'El título de la página'
    end

    on 'dni' do
      render 'dni', titulo: 'Ingrese su DNI'
    end

    on 'codigo' do
      render 'codigo', titulo: 'Ingrese su Código de Acceso'
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
        usuario = Usuario.where(dni: session.delete[:dni], codigo: codigo).take

        if usuario.present?
          flash[:mensaje] = "Le damos la bienvenida #{usuario.nombre}"
          flash[:tipo] = 'alert-info'

          siguiente = usuario.admin? ? '/carga' : '/descarga'

          res.redirect siguiente
        else
          flash[:mensaje] = 'error de identificación'
          flash[:tipo] = 'alert-danger'

          res.redirect '/'
        end
      end
    end
  end
end
