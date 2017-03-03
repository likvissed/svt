class CreateRoles < ActiveRecord::Migration[5.0]
  def change
    create_table :roles do |t|
      t.string :name, limit: 64
      t.string :short_description, limit: 64
      t.string :long_description

      t.timestamps
    end
  end
end
