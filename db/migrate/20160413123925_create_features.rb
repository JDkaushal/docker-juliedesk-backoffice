class CreateFeatures < ActiveRecord::Migration[4.2]
  def change
    create_table :features do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :active_mode, :string, default: "none"
      t.column :active_data, :text
      t.timestamps
    end
  end
end
