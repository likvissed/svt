class CreateEtalonDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :etalon_details do |t|
      t.references  :system_unit
      t.references  :detail_type
      t.string      :device, null: false
      t.timestamps
    end
  end
end
