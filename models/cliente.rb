# Un usuario que tiene sobres que retirar. Siempre es el titular de la cuenta
class Cliente < ActiveRecord::Base
  self.table_name = 'clientes'

  has_many :sobres, inverse_of: :cliente
  has_many :logs, as: :usuario

  attr_accessor :codigo
  accepts_nested_attributes_for :sobres

  validates :tipo_documento,
    presence: true
  validates :nro_documento,
    presence: true,
    uniqueness: { scope: :tipo_documento },
    numericality: { only_integer: true }

  validates :codigo,
    numericality: { only_integer: true, allow_nil: true }

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

  def validar!(codigo)
    codigo_valido?(codigo) ? self : false
  end

  def admin?
    false
  end
end
