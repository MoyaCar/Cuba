# Un usuario que puede o no ser admin, con un código de acceso y sus Sobres
class Usuario < ActiveRecord::Base
  has_many :sobres, inverse_of: :usuario

  # Para la carga de sobres no buscamos admins
  scope :normal, ->{ where admin: false }
  scope :admin, ->{ where admin: true }

  validates :dni,
    numericality: { only_integer: true },
    uniqueness: true
  validates :codigo,
    numericality: { only_integer: true }
end
