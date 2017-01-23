class AddAnnotatedReplyToMessgeClassifications < ActiveRecord::Migration
  def change
    add_column :message_classifications, :annotated_reply, :text
  end
end
