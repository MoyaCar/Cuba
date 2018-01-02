class SobreDecorator
  attr_reader :sobre

  delegate :id, :estado, :nro_proveedor, :nro_alternativo, :cliente, to: :sobre
  delegate :nombre, :tipo_documento, :nro_documento, to: :cliente

  def initialize(sobre)
    @sobre = sobre
  end

  def presente?
    estado == 'montado'
  end

  def cargable?
    estado == 'no_montado' || estado == 'descargado'
  end
end
