require_relative '../boot'

# Datos de prueba
un_admin = Usuario.create dni: 30000000, nombre: 'Juan Salvo', codigo: 1234, admin: true
un_usuario_con_sobre = Usuario.create dni: 30100000, nombre: 'Elena', codigo: 5678
un_usuario_sin_sobre = Usuario.create dni: 30200000, nombre: 'Martita', codigo: 5678
un_usuario_sin_lugar = Usuario.create dni: 30300000, nombre: 'Favalli', codigo: 5678

un_sobre = Sobre.create angulo: 1, nivel: 1, usuario: un_usuario_con_sobre
