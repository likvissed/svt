class AddUsernameToStandartLog < ActiveRecord::Migration[5.0]
  def change
    add_column :standart_logs, :username, :string, after: :item_id
    remove_reference :standart_logs, :user
  end
end
