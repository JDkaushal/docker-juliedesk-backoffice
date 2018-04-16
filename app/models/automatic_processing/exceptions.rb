module AutomaticProcessing

  module Exceptions
    AI_PROCESSING_ERROR = :ai_processing_error
    GENERIC_ERROR       = :generic_error


    class AutomaticProcessingError < StandardError
    end

    class AutomaticMessageProcessingError < AutomaticProcessingError
      attr_reader :message_id
      def initialize(message_id)
        @message_id = message_id
      end
    end

    class NoAccountAssociatedError < AutomaticProcessingError
      attr_reader :messages_thread_id
      def initialize(messages_thread_id)
        @messages_thread_id = messages_thread_id
      end

      def to_s
        "No account associated with MessagesThread #{@messages_thread_id}"
      end
    end

    class NoClassificationAvailableError < AutomaticMessageProcessingError
      def to_s
        "Attempting to retrigger a flow for message id #{@message_id} but No Message Classification was found"
      end
    end

    class NoJulieActionAvailableError < AutomaticProcessingError
      attr_reader :message_classification_id
      def initialize(message_classification_id)
        @message_classification_id = message_classification_id
      end

      def to_s
        "Attempting to retrigger a flow for message classification id #{@message_classification_id} but No Julie Action was found"
      end
    end

    class ConcienceInterpretationFailedError < AutomaticMessageProcessingError
      def to_s
        "Conscience interpretation failed for Message #{@message_id}"
      end
    end

    class ConscienceDatesSuggestionError < AutomaticMessageProcessingError
      def to_s
        "Conscience Dates suggestion failed for Message #{@message_id}"
      end
    end

    class ConscienceNoDatesToValidateError < AutomaticMessageProcessingError
      attr_reader :message_classification_id
      def initialize(message_classification_id)
        @message_classification_id = message_classification_id
      end

      def to_s
        "No dates to validate could be computed for the Message Classification #{@message_classification_id}"
      end
    end

    class ConscienceDatesSuggestionNotEnoughSuggestionsError < AutomaticMessageProcessingError
      def to_s
        "Conscience Dates suggestion did not returned enough suggestions for Message #{@message_id}"
      end
    end

    class NoMessageClassificationProvidedError < AutomaticMessageProcessingError
      def to_s
        "No Message Classification provided"
      end
    end

    class EventCreationError < AutomaticProcessingError
      attr_reader :julie_action_id
      def initialize(julie_action_id)
        @julie_action_id = julie_action_id
      end

      def to_s
        "Event creation failed for Julie Action #{@julie_action_id}"
      end
    end

    class EventUpdateError < AutomaticProcessingError
      attr_reader :julie_action_id
      def initialize(julie_action_id)
        @julie_action_id = julie_action_id
      end

      def to_s
        "Event creation failed for Julie Action #{@julie_action_id}"
      end
    end

    class EventFetchEventIdMissingError < AutomaticProcessingError
      attr_reader :julie_action_id
      def initialize(julie_action_id)
        @julie_action_id = julie_action_id
      end

      def to_s
        "Event creation failed for Julie Action #{@julie_action_id}"
      end
    end

    class AiVerifyDatesFailureError < AutomaticProcessingError
      attr_reader :message_classification_id
      def initialize(message_classification_id)
        @message_classification_id = message_classification_id
      end

      def to_s
        "The AI verify_dates call failed for the MessageClassification #{@message_classification_id}"
      end
    end

    class AiVerifyDatesNoDatesVerifiedError < AutomaticProcessingError
      attr_reader :message_classification_id
      def initialize(message_classification_id)
        @message_classification_id = message_classification_id
      end

      def to_s
        "The AI verify_dates call returned no verified dates for the MessageClassification #{@message_classification_id}"
      end
    end
  end
end