# Un sobre con su usuario, su posición y si fue entregado o no
class Sobre < ActiveRecord::Base
  belongs_to :usuario
end
