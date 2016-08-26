class AddHandledByAiToMessagesThread < ActiveRecord::Migration
  def change
    add_column :messages_threads, :handled_by_ai, :boolean, default: false
  end
end
