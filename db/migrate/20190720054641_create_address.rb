class CreateAddress < ActiveRecord::Migration[5.2]
  def change
    create_table :addresses do |t|
      t.string :name, null: false
      t.integer :number
      t.string :complement
      t.string :zip_code, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :kind, null: false
    end
  end
end
