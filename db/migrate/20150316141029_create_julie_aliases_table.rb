class CreateJulieAliasesTable < ActiveRecord::Migration[4.2]
  def up
    create_table :julie_aliases do |t|
      t.column :email, :string
      t.column :name, :string
      t.column :signature_fr, :text
      t.column :signature_en, :text
      t.column :footer_fr, :text
      t.column :footer_en, :text
      t.timestamps
    end
  end

  def down
    drop_table :julie_aliases
  end
end
