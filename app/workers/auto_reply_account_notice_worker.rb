class AutoReplyAccountNoticeWorker

  @queue = :messages_threads

  def self.enqueue id, email_type, email_to_send_to = nil
    Resque.enqueue(self, id, email_type,  email_to_send_to)
  end

  def self.perform id, email_type, email_to_send_to = nil
    Message.find(id).send_account_notice_email(email_type, email_to_send_to)
  end
end