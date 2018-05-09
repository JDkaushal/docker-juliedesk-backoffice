module AutomaticProcessing

  class Processor

    attr_reader :message, :message_classification, :julie_action, :email_deliverer, :thread_archiver, :data_holder

    def initialize(message_id, options = {})
      @options = options
      @message = Message.find(message_id)

      # This is a hack to avoid auto save on model.association = [] (should be done differently)
      dup_message = options.fetch(:dup_message, false)
      @message = @message.dup if dup_message
      ###

      raise AutomaticProcessing::Exceptions::NoAccountAssociatedError.new(@message.messages_thread_id) unless @message.messages_thread.account
    end

    def generate_classification
      # Build interpretations
      @message.interprete(force_reinterpretation: true)
      initialize_data_holder
      initialize_process_helpers
      message_classification = classify_message
      message_classification
    end

    def process!(options={})
      # Generate message interpretations
      interprete!

      # Then compute required data
      initialize_data_holder
      initialize_process_helpers

      # classify
      classify_and_create_julie_action

      if options[:dont_trigger_action_flows]
        # Normally the save action is done after the julie action flow has been processed in trigger_julie_action_flow
        @julie_action.save
      else
        # Trigger flow
        trigger_julie_action_flow

        link_associations

        # Execute actions
        trigger_actions_flow
      end
    end

    def process(options={})
      begin
        process!(options)
      rescue AutomaticProcessing::Exceptions::AutomaticProcessingError => e
        if Rails.env.development? || Rails.env.test?
          raise(e)
        else
          Airbrake.notify(e)
          self.deliver_ai_processing_error_email(e)
        end
      rescue => e
        if Rails.env.development? || Rails.env.test?
          raise(e)
        else
          Airbrake.notify(e)
          self.deliver_generic_error_email(e)
        end
      end
    end

    def deliver_generic_error_email(e)
      @email_deliverer.deliver({is_error: true, exception: e})
    end

    def deliver_ai_processing_error_email(e)
      @email_deliverer.deliver({is_error: true, ai_processing_error: true, exception: e})
    end

    def re_trigger_flow
      interprete!
      initialize_data_holder

      # Initialize email_deliver and thread_archiver
      initialize_process_helpers

      classif = @message.message_classifications.last
      julie_action = classif.julie_action

      if classif.blank?
        raise AutomaticProcessing::Exceptions::NoClassificationAvailableError.new(@message.id)
      end

      # Cast MessageClassification to AutomaticProcessing::AutomatedMessageClassification
      classif = AutomaticProcessing::AutomatedMessageClassification.from_message_classification(classif)
      classif.julie_action = AutomaticProcessing::AutomatedJulieAction.from_julie_action(julie_action)

      @data_holder.set_message_classification(classif)

      if classif.julie_action.blank?
        raise AutomaticProcessing::Exceptions::NoJulieActionAvailableError.new(@message.id)
      end

      # Cast JulieAction to AutomaticProcessing::AutomatedJulieAction
      automated_julie_action = AutomaticProcessing::AutomatedJulieAction.from_julie_action(classif.julie_action)
      automated_julie_action.message_classification = classif
      automated_julie_action.process(suggest_again: true)

      @data_holder.set_julie_action(automated_julie_action)

      trigger_actions_flow
    end

    private

    def interprete!
      force = @options.fetch(:force_reinterpretation, false)
      @message.interprete!(force_reinterpretation: force)
      raise AutomaticProcessing::Exceptions::ConcienceInterpretationFailedError.new(@message.id) unless @message.main_message_interpretation
    end

    def trigger_actions_flow
      flow = "AutomaticProcessing::ClassificationsFlows::#{@data_holder.get_current_classification.camelize}".constantize
      flow.new.post_classification_actions.each{ |action| self.send(action) }
    end

    def classify_and_create_julie_action
      @message_classification = classify_message!
      @data_holder.set_message_classification(@message_classification)

      @julie_action = create_julie_action
      @data_holder.set_julie_action(@julie_action)
    end

    def trigger_julie_action_flow
      @julie_action.process
    end

    def classify_message!
      AutomaticProcessing::AutomatedMessageClassification.process_message!(@message)
    end

    def classify_message
      AutomaticProcessing::AutomatedMessageClassification.process_message(@message)
    end

    def create_julie_action
      AutomaticProcessing::AutomatedJulieAction.new(
        action_nature: @message_classification.computed_julie_action_nature,
        message_classification: @message_classification
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

