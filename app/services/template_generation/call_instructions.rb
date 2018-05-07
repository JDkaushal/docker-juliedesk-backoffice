module TemplateGeneration

  class CallInstructions

    CALL_WORD      = { fr: 'Appeler', en: 'Call' }
    TO_CALL_WORD   = { fr: 'appelle', en: 'to call' }
    DETAILS_PREFIX = { fr: 'au', en: 'at' }

    def self.generate(auto_message_classification, options= {})
      call_instructions_data = JSON.parse(auto_message_classification.call_instructions || {})
      call_instructions_data.merge!(attendees: auto_message_classification.get_present_attendees)
      self.new(call_instructions_data).generate_template(options)
    end


    def initialize(call_instructions_data)
      call_instructions_data = call_instructions_data.with_indifferent_access
      @present_attendees  = call_instructions_data.fetch(:attendees, [])
      @support            = call_instructions_data.fetch(:support, '')
      @target             = call_instructions_data.fetch(:target, '')
      @target_infos       = call_instructions_data.fetch(:target_infos, {})
      @details            = call_instructions_data.fetch(:details, '')
    end

    def generate_template(options = {})
      @language = options.fetch(:language, :fr)

      case @support
        when AutomaticProcessing::Flows::CallInstructions::SUPPORT_LANDLINE
          generate_call_instruction
        when AutomaticProcessing::Flows::CallInstructions::SUPPORT_MOBILE
          generate_call_instruction
        when AutomaticProcessing::Flows::CallInstructions::SUPPORT_CONFCALL
          generate_confcall_instructions
        when AutomaticProcessing::Flows::CallInstructions::SUPPORT_VIDEO_CONFERENCE
          ''
        when AutomaticProcessing::Flows::CallInstructions::SUPPORT_SKYPE
          ''
        when AutomaticProcessing::Flows::CallInstructions::SUPPORT_SKYPE_FOR_BUSINESS
          ''
        else
          ''
      end
    end


    private

    def caller
      return nil if @present_attendees.blank?
      return nil if @present_attendees.size < 2

      case @target
        when AutomaticProcessing::Flows::CallInstructions::TARGET_CLIENT
          attendees = @present_attendees.reject(&:is_thread_owner)
          caller_attendee = attendees.size > 1 ? nil : attendees.first
        when AutomaticProcessing::Flows::CallInstructions::TARGET_INTERLOCUTOR
          caller_attendee = @present_attendees.find(&:is_thread_owner)
        when AutomaticProcessing::Flows::CallInstructions::TARGET_LATER
          caller_attendee = nil
        else
          caller_attendee = nil
      end

      caller_attendee.try(:full_name)
    end


    def receiver
      @target_infos[:name]
    end

    def generate_call_instruction
      return '' if @present_attendees.blank?
      return '' if @details.blank?
      return '' if receiver.blank?

      parts = []
      parts << caller unless caller.blank?
      parts << (caller.present? ? TO_CALL_WORD[@language] : CALL_WORD[@language])
      parts << receiver
      parts << [DETAILS_PREFIX[@language], @details].join(" ")

      parts.join(" ")
    end


    def generate_confcall_instructions
      @details.to_s
    end


  end
end
