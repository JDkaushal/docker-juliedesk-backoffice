class ArchiveMessagesThreadWorker

  @queue = :messages_threads

  def self.enqueue id
    Resque.enqueue(self, id)
  end

  def self.perform id
    MessagesThread.find(id).archive
  end
end