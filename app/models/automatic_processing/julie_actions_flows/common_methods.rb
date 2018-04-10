module AutomaticProcessing
  module JulieActionsFlows

    module CommonMethods
      include TemplateGeneratorHelper

      def say_hi_text
        initial_recipients_to = @data_holder.get_message_initial_recipients[:to]

        text = get_say_hi_template({
                                       recipient_names: @data_holder.search_attendees_in_present(initial_recipients_to).map{|att| att[:assisted_by_name] || att[:usageName]},
                                       should_say_hi: true,
                                       locale: @data_holder.get_current_locale
                                   })

        if text.present?
          "#{text}\n\n"
        else
          nil
        end
      end

      def should_ask_location?

        required_data_flow = AutomaticProcessing::Flows::JulieActionRequiredDataForLocation.new(
            classification: @data_holder.get_message_classification,
            account:        @data_holder.get_thread_owner_account
        )

        required_data = required_data_flow.process_flow(@data_holder.get_julie_action_nature)

        return false if required_data.blank?

        missing_data = required_data.select do |required_field|
          @data_holder.get_message_classification.missing_field?(required_field[:field], { scope: required_field[:required_from] })
        end

        missing_data.any?
      end

      def missing_contact_info
        AutomaticProcessing::Flows::JulieActionComplementaryInfo.new(
            classification: @data_holder.get_message_classification,
            account:        @data_holder.get_thread_owner_account
        ).process_flow(@data_holder.get_julie_action_nature).try(:field)
      end
    end
  end
end