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

    #def generate_classification
    #  # Build interpretations
    #  @message.interprete(force_reinterpretation: true, full_ai_mode: true)
    #  initialize_data_holder
    #  initialize_process_helpers
    #  message_classification = classify_message
    #  message_classification
    #end

    def process!(options={})
      # Generate message interpretations
      interprete!

      # Then compute required data
      initialize_data_holder
      initialize_process_helpers

      # classify
      trigger_classify

      if no_authentication_token? || scheduling_started? || !message_from_owner? || !confident?("constraints_confidence")
        return fallback_to_manuel_processing!
      else
        # Command line is present ?
        raise AutomaticProcessing::Exceptions::UnprocessableRequest.new(@message.id) unless command_line_detected?

        # Are we in a '1 client vs 1 attendee' flow ?
        raise AutomaticProcessing::Exceptions::UnprocessableRequest.new(@message.id) unless one_one_flow?

        # Are we confident enough to continue full auto process ?
        confidence_fields = ['location', 'duration', 'appointment']
        not_confident_fields = confidence_fields.reject { |confidence_field| confident?("#{confidence_field}_confidence") }
        raise AutomaticProcessing::Exceptions::CommandLineNotUnderstood.new(not_confident_fields) if not_confident_fields.any?
      end


      # Create julie action
      trigger_julie_action_creation


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
      process!(options)
    rescue  AutomaticProcessing::Exceptions::CommandLineNotUnderstood,
            AutomaticProcessing::Exceptions::UnprocessableRequest,
            AutomaticProcessing::Exceptions::ConscienceDatesSuggestionNotEnoughSuggestionsError => e
        self.deliver_error_email(e)
    ensure
      # Tracking
      messages_thread = @message.messages_thread
      if messages_thread.messages.flat_map(&:message_classifications).count == 1
        ClientSuccessTrackingHelpers.async_track_new_request_sent(messages_thread.id)
      end
    end

    def deliver_error_email(e)
      @email_deliverer.deliver({is_error: true, exception: e})
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

    def one_one_flow?
      nb_client_attendees     = @message_classification.get_present_attendees.select(&:is_client).count
      nb_non_client_attendees = @message_classification.get_present_attendees.reject(&:is_client).count
      nb_client_attendees == 1 && nb_non_client_attendees == 1
    end

    def confident?(confidence_field, options = {})
      min_confidence_score = options.fetch(:min_confidence_score, 0.9)
      main_interpretation_data = @message.main_message_interpretation.try(:json_response)
      return false if main_interpretation_data.empty?

      return true if main_interpretation_data[confidence_field].nil?
      main_interpretation_data[confidence_field].to_f >= min_confidence_score
    end


    def command_line_detected?
      main_interpretation_data = @message.main_message_interpretation.try(:json_response)
      return false if main_interpretation_data.empty?

      main_interpretation_data['has_command_line']
    end

    def scheduling_started?
      messages_thread = @message.messages_thread
      return false if messages_thread.nil?

      messages_thread.messages.flat_map(&:message_classifications).map(&:julie_action).compact.any? do |julie_action|
        julie_action.action_nature == JulieAction::JD_ACTION_SUGGEST_DATES
      end
    end

    def no_authentication_token?
      messages_thread = @message.messages_thread
      return true if messages_thread.nil?

      messages_thread.authentication_token.blank?
    end

    def message_from_owner?
      messages_thread = @message.messages_thread
      return false if messages_thread.nil?

      from_email = @message.get_email_from
      messages_thread.account.all_emails.include?(from_email)
    end

    private

    def interprete!
      force = @options.fetch(:force_reinterpretation, false)
      @message.interprete!(force_reinterpretation: force, full_ai_mode: true)
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

    def trigger_classify
      @message_classification = classify_message!
      @data_holder.set_message_classification(@message_classification)
    end

    def trigger_julie_action_creation
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

    def fallback_to_manuel_processing!
      @message.messages_thread.update(handled_by_ai: false)
      nil
    end

  end
end

