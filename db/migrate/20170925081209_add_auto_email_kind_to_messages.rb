class AddAutoEmailKindToMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :messages, :auto_email_kind, :string
  end
end
