class CreateAutomatedMessageClassificationsTable < ActiveRecord::Migration[4.2]
  def self.up
    ActiveRecord::Base.connection.execute("CREATE TABLE automated_message_classifications (LIKE message_classifications INCLUDING ALL);")
  end

  def self.down
    ActiveRecord::Base.connection.execute("DROP TABLE automated_message_classifications;")
  end
end
