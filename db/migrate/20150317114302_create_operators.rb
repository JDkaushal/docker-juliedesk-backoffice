class CreateOperators < ActiveRecord::Migration[4.2]
  def up
    create_table :operators do |t|
      t.column :email, :string
      t.column :name, :string
      t.column :encrypted_password, :string
      t.column :salt, :string
      t.column :privilege, :string
      t.timestamps
    end
  end

  def down
    drop_table :operators
  end
end
