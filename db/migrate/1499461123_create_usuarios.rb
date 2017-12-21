class CreateUsuarios < ActiveRecord::Migration[5.1]
  def change
    create_table :usuarios, force: true do |t|
      t.string :nombre, null: false
      t.string :tipo_documento, null: false
      t.string :nro_documento, null: false
      t.string :clave_digital, null: false
      t.boolean :admin, default: false, null: false
    end
  end
end
