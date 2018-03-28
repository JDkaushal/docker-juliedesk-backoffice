module AutomaticProcessing
  module Flows

    class JulieActionRequiredDataForLocation
      include FlowDispatcher

      class NoClassification < StandardError ; end
      class NoAccount < StandardError ; end

      APPOINTMENT_PHYSICAL = AutomaticProcessing::AutomatedMessageClassification::PHYSICAL_EVENT_TYPES
      APPOINTMENT_VIRTUAL  = AutomaticProcessing::AutomatedMessageClassification::VIRTUAL_EVENT_TYPES
      APPOINTMENT_SKYPE    = AutomaticProcessing::AutomatedMessageClassification::APPOINTMENT_TYPE_SKYPE

      BEHAVIOUR_PROPOSE           = AutomaticProcessing::AutomatedMessageClassification::APPOINTMENT_BEHAVIOUR_PROPOSE
      BEHAVIOUR_ASK_INTERLOCUTOR  = AutomaticProcessing::AutomatedMessageClassification::APPOINTMENT_BEHAVIOUR_ASK_INTERLOCUTOR
      BEHAVIOUR_ASK_LATER         = AutomaticProcessing::AutomatedMessageClassification::APPOINTMENT_BEHAVIOUR_ASK_LATER

      BEHAVIOUR_DECIDE_LATER      = 'Le client choisira plus tard'


      FLOWS = {
          JulieAction::JD_ACTION_SUGGEST_DATES => {
              before_flow: [
                  { method: :set_appointment_config,      params: [:@initial_classification, :@initial_account], store_as: :@appointment_config },
                  { method: :set_appointment_kind,        params: [:@appointment_config],                        store_as: :@appointment_kind },
                  { method: :set_appointment_behaviour,   params: [:@appointment_config],                        store_as: :@appointment_behaviour }
              ],

              flow_items: [

                  # Physical apointments
                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_PHYSICAL ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_DECIDE_LATER ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ ] ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_PHYSICAL ] },
                          { method: :behaviour_is_not?,     params: [ :@appointment_behaviour, BEHAVIOUR_DECIDE_LATER ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :location, required_from: :anyone }] ], exit_flow: true }
                      ]
                  },


                  # Skype Appointment
                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_SKYPE ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_ASK_LATER ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [] ] }
                      ]
                  },

                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_SKYPE ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_PROPOSE ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :skype, required_from: :thread_owner } ] ], exit_flow: true }
                      ]
                  },


                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_SKYPE ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_ASK_INTERLOCUTOR ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :skype, required_from: :attendees } ] ], exit_flow: true }
                      ]
                  },


                  # Virtual Appointment
                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind, APPOINTMENT_VIRTUAL ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_ASK_LATER ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [] ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind, APPOINTMENT_VIRTUAL ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, [BEHAVIOUR_PROPOSE] ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :any_number, required_from: :thread_owner } ] ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind, APPOINTMENT_VIRTUAL ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, [BEHAVIOUR_ASK_INTERLOCUTOR] ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :any_number, required_from: :attendees } ] ], exit_flow: true }
                      ]
                  },

                  # Fallback
                  {
                      actions: [ { method: :return_value, params: [[]], exit_flow: true } ]
                  }
              ]
          },

          JulieAction::JD_ACTION_CHECK_AVAILABILITIES => {
              before_flow: [
                  { method: :set_appointment_config,      params: [:@initial_classification, :@initial_account], store_as: :@appointment_config },
                  { method: :set_appointment_kind,        params: [:@appointment_config],                        store_as: :@appointment_kind },
                  { method: :set_appointment_behaviour,   params: [:@appointment_config],                        store_as: :@appointment_behaviour },
              ],


              flow_items: [

                  # Physical apointments
                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_PHYSICAL ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_DECIDE_LATER ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ ] ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_PHYSICAL ] },
                          { method: :behaviour_is_not?,     params: [ :@appointment_behaviour, BEHAVIOUR_DECIDE_LATER ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :location, required_from: :anyone }] ], exit_flow: true }
                      ]
                  },


                  # Skype Appointment
                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_SKYPE ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_ASK_LATER ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [] ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_SKYPE ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_PROPOSE ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :skype, required_from: :thread_owner } ] ], exit_flow: true }
                      ]
                  },


                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_SKYPE ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_ASK_INTERLOCUTOR ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :skype, required_from: :attendees } ] ], exit_flow: true }
                      ]
                  },


                  # Virtual Appointment
                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_VIRTUAL ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_ASK_LATER ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [] ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_VIRTUAL ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_PROPOSE ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :any_number, required_from: :thread_owner } ] ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :appointment_kind_is?,  params: [ :@appointment_kind,      APPOINTMENT_VIRTUAL ] },
                          { method: :behaviour_is?,         params: [ :@appointment_behaviour, BEHAVIOUR_ASK_INTERLOCUTOR ] }
                      ],

                      actions: [
                          { method: :return_value, params: [ [ { field: :any_number, required_from: :attendees } ] ], exit_flow: true }
                      ]
                  }
              ]
          },

          JulieAction::JD_ACTION_WAIT_FOR_CONTACT => {
              flow_items: [
                  {
                      conditions: [],
                      actions: []
                  }
              ]
          }

      }


      def initialize(data)
        self.init_flows!(FLOWS, data)
      end

      private

      # Init data
      def set_appointment_config(classification, account)
        return nil if account.nil?
        return nil if classification.nil?
        account.appointments.find {|appointment_config| appointment_config['kind'] == classification.appointment_nature}
      end

      def set_appointment_kind(appointment_config)
        return nil if appointment_config.nil?
        appointment_config['kind']
      end

      def set_appointment_behaviour(appointment_config)
        return nil if appointment_config.nil?

        if AutomaticProcessing::AutomatedMessageClassification::PHYSICAL_EVENT_TYPES.include?(appointment_config['kind'])
          appointment_config['default_address'] && appointment_config['default_address']['label']
        else
          appointment_config['behaviour']
        end
      end


      # Conditions
      def appointment_kind_is?(appointment_kind, kind)
        kind.is_a?(Array) ? kind.include?(appointment_kind) : kind == appointment_kind
      end

      def behaviour_is?(appointment_behaviour, behaviour)
        behaviour.is_a?(Array) ? behaviour.include?(appointment_behaviour) : behaviour == appointment_behaviour
      end

      def behaviour_is_not?(appointment_behaviour, behaviour)
        !behaviour_is?(appointment_behaviour, behaviour)
      end

      def return_value(data)
        data
      end

    end

  end
end