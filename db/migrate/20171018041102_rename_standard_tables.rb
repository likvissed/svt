class RenameStandardTables < ActiveRecord::Migration[5.0]
  def change
    rename_table :standart_discrepancies, :standard_discrepancies
    rename_table :standart_logs, :standard_logs
    rename_table :standart_log_details, :standard_log_details
  end
end
