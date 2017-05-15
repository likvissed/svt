class RenameInfoColumnInUser < ActiveRecord::Migration[5.0]
  def change
    rename_column :users, :info, :fullname
  end
end
