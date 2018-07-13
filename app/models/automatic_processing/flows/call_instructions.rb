module AutomaticProcessing
  module Flows

    class CallInstructions
      include FlowDispatcher

      BEHAVIOUR_PROPOSE           = AutomaticProcessing::AutomatedMessageClassification::APPOINTMENT_BEHAVIOUR_PROPOSE
      BEHAVIOUR_ASK_INTERLOCUTOR  = AutomaticProcessing::AutomatedMessageClassification::APPOINTMENT_BEHAVIOUR_ASK_INTERLOCUTOR
      BEHAVIOUR_ASK_LATER         = AutomaticProcessing::AutomatedMessageClassification::APPOINTMENT_BEHAVIOUR_ASK_LATER
      BEHAVIOUR_NONE              = ""

      TARGET_CLIENT               = 'client'
      TARGET_INTERLOCUTOR         = 'interlocutor'
      TARGET_LATER                = 'later'

      SUPPORT_MOBILE              = 'mobile'
      SUPPORT_LANDLINE            = 'landline'
      SUPPORT_SKYPE               = 'skype'
      SUPPORT_SKYPE_FOR_BUSINESS  = 'skype_for_business'
      SUPPORT_CONFCALL            = 'confcall'
      SUPPORT_VIDEO_CONFERENCE    = 'video_conference'

      FLOWS = {
          'GET_CALL_INSTRUCTIONS' => {
              before_flow: [
                  { method: :set_appointment_config,        params: [:@initial_classification], store_as: :@appointment_config },
                  { method: :set_appointment_support,       params: [:@appointment_config],     store_as: :@appointment_support },
                  { method: :set_present_attendees,         params: [:@initial_classification], store_as: :@present_attendees },
                  { method: :set_thread_owner,              params: [:@initial_classification], store_as: :@thread_owner },
                  { method: :set_behaviour,                 params: [:@appointment_config],     store_as: :@behaviour }
              ],

              flow_items: [
                {
                    conditions: [
                        { method: :behaviour_is?, params: [:@behaviour, BEHAVIOUR_PROPOSE] }
                    ],
                    actions: [
                        { method: :set_target,            params: [TARGET_CLIENT],                          store_as: :@target },
                        { method: :compute_target_infos,  params: [:@thread_owner],                         store_as: :@target_infos },
                        { method: :compute_support,       params: [:@appointment_support, :@thread_owner],  store_as: :@support },
                        { method: :compute_details,       params: [:@thread_owner, :@support],              store_as: :@details }
                    ]
                },

                {
                    conditions: [
                        { method: :behaviour_is?,  params: [:@behaviour, BEHAVIOUR_ASK_INTERLOCUTOR] },
                        { method: :has_one?,       params: [:@present_attendees] },
                    ],
                    actions: [
                        { method: :set_target,            params: [TARGET_INTERLOCUTOR],                        store_as: :@target },
                        { method: :get_first,             params: [:@present_attendees],                        store_as: :@unique_attendee },
                        { method: :compute_target_infos,  params: [:@unique_attendee],                          store_as: :@target_infos },
                        { method: :compute_support,       params: [:@appointment_support, :@unique_attendee],   store_as: :@support },
                        { method: :compute_details,       params: [:@unique_attendee, :@support],               store_as: :@details }
                    ]
                },

                {
                    conditions: [
                        { method: :behaviour_is?,  params: [:@behaviour, BEHAVIOUR_ASK_INTERLOCUTOR] },
                        { method: :has_many?,      params: [:@present_attendees] },
                    ],
                    actions: [
                        { method: :set_target,      params: [TARGET_INTERLOCUTOR],    store_as: :@target },
                        { method: :compute_support, params: [:@appointment_support],  store_as: :@support },
                        { method: :set_details,     params: [''],                     store_as: :@details }
                    ]
                },


                {
                    conditions: [
                        { method: :behaviour_is?, params: [:@behaviour, BEHAVIOUR_ASK_LATER] }
                    ],
                    actions: [
                        { method: :set_target,      params: [TARGET_LATER],         store_as: :@target },
                        { method: :set_support,     params: [''],                   store_as: :@support },
                        { method: :set_details,     params: [''],                   store_as: :@details }
                    ]
                },


                {
                    conditions: [
                        { method: :behaviour_is?, params: [:@behaviour, BEHAVIOUR_NONE] }
                    ],
                    actions: [
                        { method: :set_target,      params: [TARGET_LATER],         store_as: :@target },
                        { method: :set_support,     params: [''],                   store_as: :@support },
                        { method: :set_details,     params: [''],                   store_as: :@details }
                    ]
                },

                # Return value
                {
                    actions: [
                        { method: :return_call_instructions, params: [:@target, :@support, :@target_infos, :@details], exit_flow: true  }
                    ]
                }
              ]

          },

      }


      def initialize(data)
        self.init_flows!(FLOWS, data)
      end


      # Initial data
      def set_appointment_config(classification)
        account = classification.send(:account)
        return nil if account.nil?
        account.appointments.find {|appointment_config| appointment_config['kind'] == classification.appointment_nature}
      end

      def set_behaviour(appointment_config)
        appointment_config['behaviour'].to_s
      end

      def set_appointment_support(appointment_config)
        support_config = appointment_config['support_config_hash']
        return nil if support_config.nil?
        support_config['label']
      end

      def set_present_attendees(classification)
        classification.get_present_attendees.reject(&:is_thread_owner)
      end

      def set_thread_owner(classification)
        classification.get_thread_owner_attendee
      end


      # Conditions
      def behaviour_is?(behaviour, value_to_match)
        behaviour == value_to_match
      end

      def appointment_support_is?(label, value_to_match)
        label == value_to_match
      end


      # Utils
      def has_one?(array)
        array.size == 1
      end

      def has_many?(array)
        array.size > 1
      end

      def get_first(array)
        array.first
      end


      # Actions
      def set_target(value)
        value
      end

      def set_support(value)
        value
      end

      def set_details(value)
        value
      end

      def compute_support(appointment_support, attendee = nil)
        if attendee && !attendee.is_thread_owner
          support = SUPPORT_MOBILE      if attendee.mobile.present?
          support ||= SUPPORT_LANDLINE  if attendee.landline.present?
          return support if support.present?
        end

        case appointment_support
          when 'Mobile'
            (attendee.present? && attendee.is_thread_owner) ? SUPPORT_MOBILE : ''
          when 'Landline'
            SUPPORT_LANDLINE
          when 'Skype'
            SUPPORT_SKYPE
          when 'Skype For Business'
            SUPPORT_SKYPE_FOR_BUSINESS
          when 'Confcall'
            (attendee.present? && attendee.is_thread_owner) ? SUPPORT_CONFCALL : ''
          when 'Webex'
            SUPPORT_CONFCALL
          when 'Video Conference'
            (attendee.present? && attendee.is_thread_owner) ? SUPPORT_VIDEO_CONFERENCE : ''
          else
            ''
        end
      end

      def compute_target_infos(attendee)
        {
            email: attendee.email,
            name: attendee.full_name.present? ? attendee.full_name  : attendee.email
        }
      end

      def compute_details(attendee, support)
        return '' if attendee.nil?

        case support
          when SUPPORT_MOBILE
            attendee.mobile
          when SUPPORT_LANDLINE
            attendee.landline
          when SUPPORT_SKYPE
            attendee.skype_id
          when SUPPORT_SKYPE_FOR_BUSINESS
            # TODO: insert skype for business link
            attendee.skype_id
          when SUPPORT_CONFCALL
            attendee.confcall_instructions
          when SUPPORT_VIDEO_CONFERENCE
            ''
          else
            ''
        end
      end

      def return_call_instructions(target, support, target_infos, details)
        {
            target:       target.to_s,
            support:      support.to_s,
            targetInfos:  target_infos || {},
            details:      details.to_s,
            guid: 0,
        }
      end

    end
  end
end