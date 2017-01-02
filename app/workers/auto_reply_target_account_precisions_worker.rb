class AutoReplyTargetAccountPrecisionsWorker

  @queue = :messages_threads

  def self.enqueue id
    Resque.enqueue(self, id)
  end

  def self.perform id
    Message.find(id).auto_reply_target_account_precisions_email
  end
end