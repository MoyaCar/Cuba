# Un usuario que puede o no ser admin, con un código de acceso y sus sobres
class Usuario < ActiveRecord::Base
  has_many :sobres
end
