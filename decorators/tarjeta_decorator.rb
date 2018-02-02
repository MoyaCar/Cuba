class TarjetaDecorator
  attr_reader :tarjeta

  delegate :cliente, :sobre, to: :tarjeta
  delegate :nombre_titular, :tipo_documento, :nro_documento, to: :cliente
  delegate :nro_proveedor, :nro_alternativo, to: :sobre

  def initialize(tarjeta)
    @tarjeta = tarjeta
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

  def sobre_id
    sobre.id
  end

  def codigo_de_barras
    [Configuracion.prefijo_nro_proveedor, sobre.nro_proveedor].join
  end

  def nombre
    tarjeta.nombre.titleize
  end

  def nombre_titular
    cliente.nombre.titleize
  end
end
