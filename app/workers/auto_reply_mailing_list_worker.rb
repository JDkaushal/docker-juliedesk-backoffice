class AutoReplyMailingListWorker

  @queue = :messages_threads

  def self.enqueue id
    Resque.enqueue(self, id)
  end

  def self.perform id
    Message.find(id).auto_reply_mailing_list
  end
end