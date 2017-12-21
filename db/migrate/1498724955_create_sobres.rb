class CreateSobres < ActiveRecord::Migration[5.1]
  def change
    create_table :sobres, force: true do |t|
      t.references :cliente
      t.integer :posicion
      t.integer :nivel
      t.boolean :entregado, default: false, null: false
    end
  end
end
