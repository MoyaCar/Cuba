require_relative '../boot'

# Datos de prueba
un_admin = Usuario.create dni: 30000000, nombre: 'Juan Salvo', codigo: 1234, admin: true
usuario = Usuario.create dni: 30100000, nombre: 'Elena Martita', codigo: 5678

Sobre.create angulo: 100, nivel: 2, usuario: usuario
