class CreateUsuarios < ActiveRecord::Migration[5.1]
  def change
    create_table :usuarios, force: true do |t|
      t.string :nombre, null: false
      t.integer :dni, null: false
      t.string :codigo, null: false
      t.boolean :admin, default: false, null: false
    end
  end
end
