class CreateClientContacts < ActiveRecord::Migration
  def change
    create_table :client_contacts do |t|
      t.string :client_email, null: false
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :usage_name
      t.string :gender
      t.boolean :is_assistant
      t.boolean :assisted
      t.string :assisted_by
      t.string :company
      t.string :timezone
      t.string :landline
      t.string :mobile
      t.string :skypeId
      t.text :conf_call_instructions

      t.timestamps
    end

    add_index :client_contacts, [:client_email, :email], unique: true
  end
end
