class AutoReplyAccountConfigurationPendingWorker

  @queue = :messages_threads

  def self.enqueue id
    Resque.enqueue(self, id)
  end

  def self.perform id
    Message.find(id).send_account_configuration_pending_email
  end
end