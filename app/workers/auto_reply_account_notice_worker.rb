class AutoReplyAccountNoticeWorker

  @queue = :messages_threads

  def self.enqueue id, email_type, email_to_send_to = nil, client_usage_name = nil, identifier = nil
    Resque.enqueue(self, id, email_type,  email_to_send_to, client_usage_name, identifier)
  end

  def self.perform id, email_type, email_to_send_to = nil, client_usage_name = nil, identifier = nil
    Message.find(id).send_account_notice_email(email_type, email_to_send_to, client_usage_name, identifier)
  end
end