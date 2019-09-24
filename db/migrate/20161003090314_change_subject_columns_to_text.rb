class ChangeSubjectColumnsToText < ActiveRecord::Migration[4.2]
  def change
    change_column :messages_threads, :subject, :text
  end
end
