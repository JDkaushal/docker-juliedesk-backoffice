module Archiver

  def self.archive_old_threads
    messages_thread_ids = messages_thread_ids_to_archive
    messages_thread_ids.each do |messages_thread_id|
      ArchiveWorker.enqueue messages_thread_id
    end
    messages_thread_ids.length
  end


  def remove_anonymised_threads_from_archive_database
    ActiveRecord::Base.establish_connection(Rails.configuration.database_configuration["archive_anonymised_#{Rails.env}"])
    anonymised_thread_ids = ActiveRecord::Base.connection.execute("SELECT threads.id FROM threads").to_a.map{|thread| thread['id'].to_i}

    ActiveRecord::Base.establish_connection(Rails.configuration.database_configuration["archive_#{Rails.env}"])
    messages_thread_ids_anonymised = MessagesThread.where(id: anonymised_thread_ids).map(&:id)

    messages_thread_ids_with_no_messages = MessagesThread.includes(:messages).where(messages: {id: nil}).map(&:id)

    messages_thread_ids_with_no_message_classsifications = MessagesThread.includes(messages: {message_classifications: {}}).where(message_classifications: {id: nil}).map(&:id)

    messages_thread_ids_to_delete = messages_thread_ids_anonymised +
        messages_thread_ids_with_no_messages +
        messages_thread_ids_with_no_message_classsifications


    puts "#{messages_thread_ids_to_delete.length} threads to delete."
    messages_thread_ids_to_delete.each_with_index do |messages_thread_id_to_delete, index|
      puts "#{index}/#{messages_thread_ids_to_delete.length}"
      objects_to_delete = Archiver.get_objects_to_move(messages_thread_id_to_delete)
      ActiveRecord::Base.transaction do
        objects_to_delete.each do |object_to_delete|
          object_to_delete.delete
        end
      end
    end
  end

  def self.messages_thread_ids_to_archive
    ActiveRecord::Base.connection.execute(<<-SQL.strip_heredoc
SELECT DISTINCT(messages_threads.id)
FROM messages_threads
LEFT JOIN messages ON
  (
    messages.messages_thread_id = messages_threads.id AND
    messages.received_at > '#{(DateTime.now - 6.months).to_s}'
  )
WHERE messages.id IS NULL
SQL
).map{|r| r['id'].to_i}
  end


  def self.archive_messages_thread(messages_thread_id)
    objects_to_move = self.get_objects_to_move(messages_thread_id)

    current_conf = ActiveRecord::Base.connection_config

    begin
      ActiveRecord::Base.establish_connection(Rails.configuration.database_configuration["archive_#{Rails.env}"])

      begin
        objects_to_move.each do |object|
          object.class.create object.attributes
        end
      rescue ActiveRecord::RecordNotUnique => e
        objects_to_delete = self.get_objects_to_move(messages_thread_id)

        objects_to_delete.each do |object_to_delete|
          object_to_delete.delete
        end

        objects_to_move.each do |object|
          object.class.create object.attributes
        end

      end


      ActiveRecord::Base.establish_connection current_conf

      objects_to_move.each do |object|
        object.delete
      end

      ActiveRecord::Base.connection.execute("DELETE FROM versions WHERE item_type = '#{MessagesThread}' AND item_id = #{messages_thread_id}")
    ensure
      ActiveRecord::Base.establish_connection current_conf
    end

  end

  def self.get_objects_to_move(messages_thread_id)
    messages_thread = MessagesThread.includes(messages: {message_classifications: {julie_action: [:date_suggestions_comparison_review, :date_suggestions_review]}, auto_message_classification: :auto_message_classification_reviews, message_interpretations: {}, automated_message_classifications: :julie_action}, operator_actions_groups: :operator_actions).find(messages_thread_id)
    messages = messages_thread.messages
    message_classifications = messages.map(&:message_classifications).flatten.compact
    julie_actions = message_classifications.map(&:julie_action).flatten.compact

    automated_message_classifications = messages.map(&:automated_message_classifications).flatten.compact
    automated_julie_actions = automated_message_classifications.map(&:julie_action).flatten.compact

    date_suggestions_comparison_reviews = julie_actions.map(&:date_suggestions_comparison_review).flatten.compact
    date_suggestions_reviews = julie_actions.map(&:date_suggestions_review).flatten.compact

    auto_message_classifications = messages.map(&:auto_message_classification).flatten.compact
    auto_message_classification_reviews = auto_message_classifications.map(&:auto_message_classification_reviews).flatten.compact

    message_interpretations = messages.map(&:message_interpretations).flatten.compact

    operator_actions_groups = messages_thread.operator_actions_groups
    operator_actions = operator_actions_groups.map(&:operator_actions).flatten.compact

        [messages_thread] +
            messages +
            message_interpretations +
            message_classifications +
            julie_actions +
            date_suggestions_comparison_reviews +
            date_suggestions_reviews +
            auto_message_classifications +
            auto_message_classification_reviews +
            operator_actions_groups +
            operator_actions
  end

end