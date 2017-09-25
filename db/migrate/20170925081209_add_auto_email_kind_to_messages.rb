class AddAutoEmailKindToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :auto_email_kind, :string
  end
end
