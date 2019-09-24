class Rename < ActiveRecord::Migration[4.2]
  def change
    rename_table :client_requests_tables, :client_requests
  end
end
