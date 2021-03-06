class AutoEmailWorker

  @queue = :messages_threads

  def self.enqueue id, email_type, translation_params, email_to_send_to = nil
    Resque.enqueue(self, id, email_type, translation_params,  email_to_send_to)
  end

  def self.perform id, email_type, translation_params, email_to_send_to = nil
    AutomaticsEmails::Manager.new(Message.find(id)).send(email_type, translation_params, email_to_send_to)

    #Message.find(id).send_auto_email(email_type, translation_params, email_to_send_to)
  end
end