class SobreDecorator
  attr_reader :sobre

  delegate :id, :nro_proveedor, :nro_alternativo, :cliente, to: :sobre
  delegate :nombre, :tipo_documento, :nro_documento, to: :cliente

  def initialize(sobre)
    @sobre = sobre
  end

  def presente?
    sobre.estado == 'montado'
  end

  def cargable?
    sobre.estado == 'no_montado' || sobre.estado == 'descargado'
  end

  def estado
    sobre.estado.titleize
  end

  def codigo_de_barras
    [Configuracion.prefijo_nro_proveedor, sobre.nro_proveedor].join
  end
end
