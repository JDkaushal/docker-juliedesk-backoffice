require 'resque/plugins/workers/lock'

class ImportEmailsWorker

  extend Resque::Plugins::Workers::Lock

  # Queues priority are alphabetically defined
  # So we prepend a 'a' to make this worker a high priority
  @queue = :aa_import_emails

  def self.lock_workers
    :import_emails
  end

  # We will unlock the worker in 3 minutes in case something goes wrong
  def self.worker_lock_timeout
    360
  end

  def self.enqueue
    Rails.logger.info 'Enqueuing ImportEmailsWorker...'
    Resque.enqueue(self)
  end

  def self.perform
    Rails.logger.info 'Importing Emails'
    print "Importing Emails\n"
    updated_messages_thread_ids = Message.import_emails
    if updated_messages_thread_ids.present? && updated_messages_thread_ids.size > 0
      WebSockets::Manager.trigger_new_email(updated_messages_thread_ids)
    end
  end
end