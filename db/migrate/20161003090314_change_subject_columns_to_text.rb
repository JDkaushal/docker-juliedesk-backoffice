class ChangeSubjectColumnsToText < ActiveRecord::Migration
  def change
    change_column :messages_threads, :subject, :text
  end
end
