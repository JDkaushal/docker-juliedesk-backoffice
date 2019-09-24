class AddHandledByAiToMessagesThread < ActiveRecord::Migration[4.2]
  def change
    add_column :messages_threads, :handled_by_ai, :boolean, default: false
  end
end
