module AutomaticProcessing
  class ThreadArchiver

    attr_reader :data_holder

    def initialize(data_holder)
      @data_holder = data_holder
    end

    def archive
      archive_thread
    end

    private

    def archive_thread
      thread_status = @data_holder.get_message_classification_computed_thread_status
      message_classification = @data_holder.get_message_classification
      message_classification.update(thread_status: thread_status)

      messages_thread = @data_holder.get_messages_thread

      EmailServer.archive_thread(messages_thread_id: messages_thread.server_thread_id)

      messages_thread.messages.update_all(archived: true)

      thread_params = {
          should_follow_up: false,
          status: thread_status,
          in_inbox: false
      }

      if thread_params[:status] == MessageClassification::THREAD_STATUS_SCHEDULING_ABORTED
        thread_params[:aborted_at] = DateTime.now
      end

      messages_thread.update(thread_params)
      WebSockets::Manager.trigger_archive(messages_thread.id)
    end
  end

end