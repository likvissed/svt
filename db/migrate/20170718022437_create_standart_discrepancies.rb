class CreateStandartDiscrepancies < ActiveRecord::Migration[5.0]
  def change
    create_table :standart_discrepancies do |t|
      t.references :item
      t.references :property_value
      t.integer :event
      t.string :new_value
      t.timestamps
    end
  end
end
