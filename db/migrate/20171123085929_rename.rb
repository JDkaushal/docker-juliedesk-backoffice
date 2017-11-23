class Rename < ActiveRecord::Migration
  def change
    rename_table :client_requests_tables, :client_requests
  end
end
