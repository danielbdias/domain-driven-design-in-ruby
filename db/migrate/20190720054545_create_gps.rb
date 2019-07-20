class CreateGps < ActiveRecord::Migration[5.2]
  def change
    create_table :gps do |t|
      t.string :gps_type, null: false
    end
  end
end
