class CreateSobres < ActiveRecord::Migration[5.1]
  def change
    create_table :sobres, force: true do |t|
      t.references :usuario
      t.integer :angulo
      t.integer :nivel
      t.boolean :entregado, default: false, null: false
    end
  end
end
