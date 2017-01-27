class CreateLogDetails < ActiveRecord::Migration[5.0]
  def change
    create_table :log_details do |t|
      t.references :log
      t.references :detail_type
      t.string :old_detail
      t.string :new_detail
      t.timestamps
    end
  end
end
