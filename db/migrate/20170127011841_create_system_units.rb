class CreateSystemUnits < ActiveRecord::Migration[5.0]
  def change
    create_table :system_units do |t|
      t.string  :invnum,          limit: 50, null: false
      t.integer :tn_responsible,  unsigned: true
      t.integer :division,        unsigned: true
      t.boolean :etalon_status,   null: false
      t.integer :workplace_id,    unsigned: true
      t.timestamps
    end
  end
end
