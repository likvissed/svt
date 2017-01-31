class CreateLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :logs do |t|
      t.references  :system_unit
      t.string      :username,    null: false
      t.integer     :event,       null: false
      t.timestamps
    end
  end
end
