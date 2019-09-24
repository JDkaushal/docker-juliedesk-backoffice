class AddAnnotatedReplyToMessgeClassifications < ActiveRecord::Migration[4.2]
  def change
    add_column :message_classifications, :annotated_reply, :text
  end
end
