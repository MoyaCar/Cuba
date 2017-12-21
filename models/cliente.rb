# Un usuario que tiene sobres que retirar
class Cliente < ActiveRecord::Base
  self.table_name = 'clientes'

  has_many :sobres, inverse_of: :cliente
  has_many :logs, as: :usuario

  attr_accessor :codigo

  validates :tipo_documento, inclusion: { in: Novedad::DOCUMENTOS.keys }
  validates :nro_documento,
    presence: true,
    uniqueness: true,
    numericality: { only_integer: true }
  validates :codigo,
    numericality: { only_integer: true }

  def generar_clave_digital(codigo)
    input = [
      nro_documento.rjust(13, '0'),
      codigo
    ].join

    Digest::SHA256.hexdigest input
  end

  def codigo_valido?(codigo)
    generar_clave_digital(codigo) == clave_digital
  end
end
