class CreateTableAutomatedJulieAction < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.execute("CREATE TABLE automated_julie_actions (LIKE julie_actions INCLUDING ALL);")
    add_column :automated_julie_actions, :ai_event_data, :json, default: {}
  end

  def self.down
    ActiveRecord::Base.connection.execute("DROP TABLE automated_julie_actions;")
  end
end
