class AutomaticProcessing::AutomatedJulieAction < JulieAction

  include TemplateGeneratorHelper
  include ApplicationHelper

  attr_accessor :data_holder

  def initialize(params = {})
    @data_holder = params.delete(:data_holder)

    super(params)
  end

  def process
    return nil if self.message_classification.nil?

    if self.action_nature == JD_ACTION_SUGGEST_DATES
      AutomaticProcessing::JulieActionsFlows::SuggestDates.new(self).trigger
    elsif self.action_nature == JD_ACTION_CHECK_AVAILABILITIES
      AutomaticProcessing::JulieActionsFlows::CheckAvailabilities.new(self).trigger
    elsif self.action_nature == JD_ACTION_WAIT_FOR_CONTACT
      AutomaticProcessing::JulieActionsFlows::WaitForContact.new(self).trigger
    elsif self.action_nature == JD_ACTION_WAIT_FOR_CONTACT
      self.text = get_wait_for_contact_template({
                                                    locale: locale
                                              })

    elsif self.action.nature == JD_ACTION_WAIT_FOR_CONTACT
      # TODO : implement
    elsif self.action  == JD_ACTION_SEND_CONFIRMATION
      # TODO : impelement
    else
      # elsif self.julie_action.action_nature == JD_ACTION_NOTHING_TO_DO
    #
    #
    # elsif self.action_nature == JD_ACTION_FORWARD_TO_SUPPORT
    #   self.text = get_forward_to_support_template({
    #                                                   locale: locale
    #                                               })
    #
    # elsif self.action_nature == JD_ACTION_FORWARD_TO_CLIENT
    #   self.text = get_forward_to_client_template({
    #                                                  locale: locale
    #                                              })
    end

    save
  end

  private

  def find_dates_to_suggest
    date_suggestions_response = AI_PROXY_INTERFACE.build_request(:fetch_dates_suggestions, {
      account_email: account.email,
      thread_data: incoming_message.messages_thread.computed_data([self.message_classification]),
      raw_constraints_data: JSON.parse(message_classification.constraints_data || "[]"),
      n_suggested_dates: 4,
      attendees: [],
      asap: message_classification.asap_constraint,
      message_id: nil # Keep this to nil, if set it is used to get previously suggested dates, if not set it causes errors
    })

    if !date_suggestions_response || date_suggestions_response[:error]
      raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionError.new(self.message_classification.message.id)
    end

    date_suggestions = date_suggestions_response['suggested_dates'] || []
    if date_suggestions.length < 2
      raise AutomaticProcessing::Exceptions::ConscienceDatesSuggestionNotEnoughSuggestionsError.new(self.message_classification.message.id)
    end

    date_suggestions.map{|date_suggestion|
      {
        timezone: date_suggestions_response['timezone'],
        date: date_suggestion
      }
    }
  end

  def say_hi_text
    text = get_say_hi_template({
                            recipient_names: attendees.map{|att| att[:assisted_by_name] || att[:usageName]},
                            should_say_hi: true,
                            locale: locale
                        })

    if text.present?
      "#{text}\n\n"
    else
      nil
    end
  end

  def incoming_message
    @data_holder.get_message
  end

  def locale
    @data_holder.get_current_locale
  end

  def account
    @data_holder.get_thread_owner_account
  end

  def client_timezone
    account.default_timezone_id
  end

  def appointment_wordings
    @data_holder.get_appointment
  end

  def client_names
    @data_holder.get_client_names
  end

  def attendees
    @data_holder.get_present_attendees
  end

  def current_appointment
    @data_holder.get_appointment
  end

  def current_address
    @data_holder.get_address
  end
end