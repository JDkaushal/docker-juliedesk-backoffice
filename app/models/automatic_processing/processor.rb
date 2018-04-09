module AutomaticProcessing

  class Processor

    attr_reader :message, :message_classification, :julie_action, :email_deliverer, :thread_archiver, :data_holder

    def initialize(message_id, options = {})
      @message = Message.find(message_id)
      @message.interprete(options[:force_reinterpretation].present?)

      raise AutomaticProcessing::Exceptions::NoAccountAssociatedError.new(message.messages_thread_id) unless message.messages_thread.account
      raise AutomaticProcessing::Exceptions::ConcienceInterpretationFailedError.new(message.id) unless message.main_message_interpretation

      initialize_data_holder
    end

    def process!
      initialize_process_helpers
      classify_and_create_julie_action
      link_associations
      trigger_actions_flow
    end

    def process
      begin
        process!
      rescue => e
        if Rails.env.development?
          raise(e)
        else
          Airbrake.notify(e)
          self.deliver_error_email(e)
        end
      end
    end

    def deliver_error_email(e)
      @email_deliverer.deliver({is_error: true, exception: e})
    end

    private

    def trigger_actions_flow
      flow = "AutomaticProcessing::ClassificationsFlows::#{@message_classification.classification.camelize}".constantize
      flow.new.post_classification_actions.each{ |action| self.send(action) }
    end

    def classify_and_create_julie_action
      @message_classification = classify_message
      @data_holder.set_message_classification(@message_classification)

      @julie_action = create_julie_action
      @julie_action.process
      @data_holder.set_julie_action(@julie_action)
    end

    def classify_message
      AutomaticProcessing::AutomatedMessageClassification.process_message(@message)
    end

    def create_julie_action
      AutomaticProcessing::AutomatedJulieAction.new(
        action_nature: @message_classification.computed_julie_action_nature,
        message_classification: @message_classification,
        #data_holder: @data_holder
      )
    end

    def initialize_data_holder
      @data_holder = AutomaticProcessing::DataHolder.new(@message)
    end

    def initialize_process_helpers
      @thread_archiver = AutomaticProcessing::ThreadArchiver.new(@data_holder)
      @email_deliverer = AutomaticProcessing::EmailDeliverer.new(@data_holder)
    end

    def link_associations
      @message.message_classifications << @message_classification
      @message_classification.julie_action = @julie_action
    end

    def deliver_email
      @email_deliverer.deliver
    end

    def archive_thread
      @thread_archiver.archive
    end

  end
end

