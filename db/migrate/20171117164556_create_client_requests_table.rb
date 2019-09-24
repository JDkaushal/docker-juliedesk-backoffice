class CreateClientRequestsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :client_requests_tables do |t|
      t.column :user_id, :integer
      t.column :team_identifier, :string
      t.column :date, :datetime
      t.column :messages_thread_id, :integer
      t.timestamps
    end

    add_index(:client_requests_tables, :user_id)
    add_index(:client_requests_tables, :team_identifier)
    add_index(:client_requests_tables, :messages_thread_id)
  end
end
