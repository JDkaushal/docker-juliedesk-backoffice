class ConscienceFullWorker

  # We are using QUEUE=* so our queues are processed in alphabetical_order
  # We add a trailing 'a' to this queue name so it will be processed before the 'conscience' one that takes long to run
  @queue = :a_conscience_full_ai
  def self.enqueue(message_id, params)
    Rails.logger.info "Enqueuing ConscienceFullWorker for Message #{message_id} with params #{params}..."
    Resque.enqueue(self, message_id, params)
  end

  def self.perform (message_id, params)
    Rails.logger.info "Performing ConscienceFullWorker for Message #{message_id} with params #{params}..."
    AutomaticProcessing::Processor.new(message_id, force_reinterpretation: true).process(params.with_indifferent_access)
    Rails.logger.info "Performed succesfully ConscienceFullWorker for Message #{message_id} with params #{params}..."
  end
end
