class ArchiveWorker

  @queue = :archive

  def self.enqueue messages_thread_id
    Resque.enqueue(self, messages_thread_id)
  end

  def self.perform messages_thread_id
    Archive.archive_messages_thread(messages_thread_id)
  end
end