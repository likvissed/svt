class CreateDetailTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :detail_types do |t|
      t.string :type_name,  limit: 50, null: false
      t.string :title,      limit: 50, null: false
      t.timestamps
    end
  end
end
