module AutomaticProcessing
  module Flows

    class JulieActionComplementaryInfo
      include FlowDispatcher

      class NoClassification < StandardError ; end
      class NoAccount < StandardError ; end

      ADDITIONAL_INFO_MOBILE               = 'mobile_only'
      ADDITIONAL_INFO_SKYPE                = 'skype_only'
      ADDITIONAL_INFO_LANDLINE_OR_MOBILE   = 'landline_or_mobile'


      FLOWS = {
          JulieAction::JD_ACTION_SUGGEST_DATES => {
              before_flow: [
                  { method: :set_appointment_config,                      params: [:@initial_classification, :@initial_account], store_as: :@appointment_config },
                  { method: :set_present_attendees_from_other_companies,  params: [:@initial_classification],                    store_as: :@present_attendees_from_other_companies },
                  { method: :set_additional_information,                  params: [:@appointment_config],                        store_as: :@additional_information }
              ],

              flow_items: [


                  {
                      conditions: [
                          { method: :additional_information_is?,  params: [ :@additional_information,                 ADDITIONAL_INFO_MOBILE ] },
                          { method: :no_attendee_has?,            params: [ :@present_attendees_from_other_companies, ADDITIONAL_INFO_MOBILE ] },
                      ],

                      actions: [
                          { method: :return_value, params: [ { field: 'mobile', ask: :attendees } ], exit_flow: true }
                      ]
                  },



                  {
                      conditions: [
                          { method: :additional_information_is?,  params: [ :@additional_information,                 ADDITIONAL_INFO_SKYPE ] },
                          { method: :no_attendee_has?,           params: [ :@present_attendees_from_other_companies, ADDITIONAL_INFO_SKYPE ] },
                      ],

                      actions: [
                          { method: :return_value, params: [ { field: 'skype', ask: :attendees } ], exit_flow: true }
                      ]
                  },



                  {
                      conditions: [
                          { method: :additional_information_is?,  params: [ :@additional_information,                 ADDITIONAL_INFO_LANDLINE_OR_MOBILE ] },
                          { method: :no_attendee_has?,           params: [ :@present_attendees_from_other_companies, ADDITIONAL_INFO_LANDLINE_OR_MOBILE ] },
                      ],

                      actions: [
                          { method: :return_value, params: [ { field: 'landline_or_mobile', ask: :attendees } ], exit_flow: true }
                      ]
                  },

                  # Fallback
                  {
                      actions: [ { method: :return_value, params: [nil], exit_flow: true } ]
                  }
              ]
          },

          JulieAction::JD_ACTION_CHECK_AVAILABILITIES => {
              before_flow: [
                  { method: :set_appointment_config,                      params: [:@initial_classification, :@initial_account], store_as: :@appointment_config },
                  { method: :set_present_attendees_from_other_companies,  params: [:@initial_classification],                    store_as: :@present_attendees_from_other_companies },
                  { method: :set_additional_information,                  params: [:@appointment_config],                        store_as: :@additional_information }
              ],

              flow_items: [

                  {
                      conditions: [
                          { method: :additional_information_is?,  params: [ :@additional_information,                 ADDITIONAL_INFO_MOBILE ] },
                          { method: :no_attendee_has?,           params: [ :@present_attendees_from_other_companies, ADDITIONAL_INFO_MOBILE ] },
                      ],

                      actions: [
                          { method: :return_value, params: [ { field: 'mobile', ask: :attendees } ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :additional_information_is?,  params: [ :@additional_information,                 ADDITIONAL_INFO_SKYPE ] },
                          { method: :no_attendee_has?,           params: [ :@present_attendees_from_other_companies,  ADDITIONAL_INFO_SKYPE ] },
                      ],

                      actions: [
                          { method: :return_value, params: [ { field: 'skype', ask: :attendees } ], exit_flow: true }
                      ]
                  },

                  {
                      conditions: [
                          { method: :additional_information_is?,  params: [ :@additional_information,                 ADDITIONAL_INFO_LANDLINE_OR_MOBILE ] },
                          { method: :no_attendee_has?,           params: [ :@present_attendees_from_other_companies, ADDITIONAL_INFO_LANDLINE_OR_MOBILE ] },
                      ],

                      actions: [
                          { method: :return_value, params: [ { field: 'landline_or_mobile', ask: :attendees } ], exit_flow: true }
                      ]
                  },

                  # Fallback
                  {
                      actions: [ { method: :return_value, params: [[]], exit_flow: true } ]
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

      def set_additional_information(appointment_config)
        return [] if appointment_config.nil?
        appointment_config['required_additional_informations']
      end

      def set_present_attendees_from_other_companies(classification)
        main_account_company = classification.send(:account).try(:company)
        classification.get_present_attendees.reject { |attendee| attendee.company == main_account_company }
      end


      # Conditions
      def additional_information_is?(additional_information, value)
        additional_information == value
      end

      def any_attendee_has?(attendees, field)
        return false unless [ADDITIONAL_INFO_LANDLINE_OR_MOBILE, ADDITIONAL_INFO_MOBILE, ADDITIONAL_INFO_SKYPE].include?(field)

        case field
          when ADDITIONAL_INFO_LANDLINE_OR_MOBILE
            attendees.any?(&:has_any_phone_number?)
          when ADDITIONAL_INFO_MOBILE
            attendees.any? { |attendee| attendee.mobile.present? }
          when ADDITIONAL_INFO_SKYPE
            attendees.any? { |attendee| attendee.skype_id.present? }
          else
            false
        end
      end

      def no_attendee_has?(attendees, field)
        !any_attendee_has?(attendees, field)
      end


      # Action
      def return_value(data)
        data
      end

    end

  end
end