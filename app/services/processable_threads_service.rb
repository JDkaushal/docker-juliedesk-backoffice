class ProcessableThreadsService

  LAST_THREAD_SYNC_THRESHOLD_IN_MINUTES = (ENV['LAST_THREAD_SYNC_THRESHOLD'] || 30).to_i

  REASON_STUCK_IN_SYNCHRONIZATON = :stuck_in_sync

  def initialize(messages_thread)
    @messages_thread = messages_thread
  end

  def self.threshold_date
    LAST_THREAD_SYNC_THRESHOLD_IN_MINUTES.minutes.ago
  end

  def self.run_verification!
    MessagesThread.in_inbox_only.not_in_admin.syncing.map do |messages_thread|
      processor = self.new(messages_thread)
      result = processor.processable_thread?
      if result.processable === false
        processor.send(:handle_result!, result.why)
        true
      else
        false
      end
    end
  end

  def processable_thread?
    if stuck_in_sync?
      return OpenStruct.new(processable: false, why: REASON_STUCK_IN_SYNCHRONIZATON)
    end

    OpenStruct.new(processable: true, why: nil)
  end


  private

  def handle_result!(reason)
    case reason
      when REASON_STUCK_IN_SYNCHRONIZATON
        handle_stuck_in_sync!
      else
        false
    end
  end

  def stuck_in_sync?
    syncing_since = @messages_thread.syncing_since
    syncing_since && syncing_since < ProcessableThreadsService.threshold_date
  end

  def handle_stuck_in_sync!

    # TODO : activate when ready to
    # Notify client about this issue
    #AutoEmailWorker.enqueue(
    #    last_message.id,
    #    AutomaticsEmails::Rules::TYPE_TECHNICAL_ISSUE,
    #    { key: 'technical_issue', client_name: @messages_thread.account.try(:usage_name) },
    #    @messages_thread.account_email
    #)

    # Notify dev about this issue

    summary = "Calendars not synchronized for thread##{@messages_thread.id}"
    return false if TicketService.ticket_exist?(summary)

    TicketWorker.enqueue(
        summary:     summary,
        description: "The present thread is still not synchronized (more than #{LAST_THREAD_SYNC_THRESHOLD_IN_MINUTES} min) : #{messages_thread_link}",
        tags: ["tek_thread_stuck_in_sync"]
    )
    true
  end

  def messages_thread_link
    "#{ENV['BACKOFFICE_BASE_URL']}/messages_threads/#{@messages_thread.id}"
  end

  def last_message
    @messages_thread.messages.reject(&:from_me).sort_by(&:received_at).last
  end

end