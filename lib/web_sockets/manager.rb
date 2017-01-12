module WebSockets
  class Manager

    def self.trigger_new_email(updated_messages_thread_ids)
      broadcast('new-email', {
          :message => 'new_email',
          :messages_threads_count => MessagesThread.items_to_classify_count,
          :updated_messages_thread_ids => updated_messages_thread_ids
      })
    end

    def self.trigger_archive(messages_thread_id)
      broadcast('archive', {
          :message => 'archive',
          :message_thread_id => messages_thread_id
      })
    end

    def self.trigger_locks_changed
      broadcast('locks-changed', {
          :message => 'locks_changed',
          :locks_statuses => MessagesThread.get_locks_statuses_hash
      })
    end

    private

    def self.broadcast(type, params)
      if ENV['PUSHER_APP_ID']
        Pusher.trigger('private-global-chat', type, params)
      elsif ENV['RED_SOCK_URL']
        RedSock.trigger('private-global-chat', type, params)
      end
    end

  end
end