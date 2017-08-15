class AddPropertyRefToStandartDiscrepancy < ActiveRecord::Migration[5.0]
  def change
    change_table :standart_discrepancies do |t|
      t.column :property_id, 'INT(10)', after: :item_id
    end

    add_foreign_key :standart_discrepancies, "#{Rails.configuration.database_configuration["#{Rails.env}_invent"]['database']}.invent_property", column: :property_id, primary_key: :property_id
  end
end
