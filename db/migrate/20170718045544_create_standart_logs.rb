class CreateStandartLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :standart_logs do |t|
      t.references :item
      t.references :user
      t.integer :event
      t.timestamps
    end
  end
end
