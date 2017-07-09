# Un usuario que puede o no ser admin, con un código de acceso y su Sobre
class Usuario < ActiveRecord::Base
  has_one :sobre

  # Para la carga de sobres no buscamos admins
  scope :normal, ->{ where admin: false }

  validates :dni,
    numericality: { only_integer: true },
    uniqueness: true
  validates :codigo,
    numericality: { only_integer: true }
end
