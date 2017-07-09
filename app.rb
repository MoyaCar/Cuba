# La definición de rutas y acciones
Cuba.define do
  on get do
    on root do
      render 'inicio', titulo: 'El título de la página'
    end

    on 'dni' do
      render 'dni', titulo: 'Ingrese su DNI'
    end
  end

  on post do
    on 'dni' do
      on param('numero') do |numero|
        usuario = Usuario.where(dni: numero).take

        if usuario.present?
          flash[:mensaje] = "gracias #{numero}"
          flash[:tipo] = 'alert-info'
        else
          flash[:mensaje] = 'error de identificación'
          flash[:tipo] = 'alert-danger'
        end

        res.redirect '/'
      end
    end
  end
end
