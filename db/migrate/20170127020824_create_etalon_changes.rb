class CreateEtalonChanges < ActiveRecord::Migration[5.0]
  def change
    create_table :etalon_changes do |t|
      t.references  :system_unit
      t.references  :detail_type
      t.string      :detail,        null: false
      t.integer     :event,         null: false
      t.timestamps
    end
  end
end
