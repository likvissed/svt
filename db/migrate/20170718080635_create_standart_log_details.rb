class CreateStandartLogDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :standart_log_details do |t|
      t.references :log
      t.references :property
      t.string :old_detail
      t.string :new_detail
      t.timestamps
    end
  end
end
