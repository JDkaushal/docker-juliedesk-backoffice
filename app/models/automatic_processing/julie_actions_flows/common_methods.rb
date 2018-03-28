module AutomaticProcessing
  module JulieActionsFlows

    module CommonMethods
      include TemplateGeneratorHelper

      def say_hi_text
        text = get_say_hi_template({
                                       recipient_names: @data_holder.get_present_attendees.map{|att| att[:assisted_by_name] || att[:usageName]},
                                       should_say_hi: true,
                                       locale: @data_holder.get_current_locale
                                   })

        if text.present?
          "#{text}\n\n"
        else
          nil
        end
      end
    end
  end
end