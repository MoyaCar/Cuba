class CreateSobres < ActiveRecord::Migration[5.1]
  def change
    create_table :sobres, force: true do |t|
      t.integer :dni, null: false
      t.integer :angulo
      t.integer :nivel
      t.boolean :entregado, default: false
    end
  end
end
