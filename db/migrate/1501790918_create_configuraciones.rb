class CreateConfiguraciones < ActiveRecord::Migration[5.1]
  def change
    create_table :configuraciones, force: true do |t|
      t.integer :espera_carga, null: false, default: 10
      t.integer :espera_extraccion, null: false, default: 15
      t.string :nombre_archivo_novedades, null: false, default: 'novedades.csv'
      t.timestamps
    end
  end
end
