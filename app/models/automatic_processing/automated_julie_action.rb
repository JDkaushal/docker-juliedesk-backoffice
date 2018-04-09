class AutomaticProcessing::AutomatedJulieAction < JulieAction

  include TemplateGeneratorHelper
  include ApplicationHelper

  def initialize(params = {})
    super(params)
  end

  def process
    return nil if self.message_classification.nil?

    puts self.message_classification.attendees.inspect


    if self.action_nature == JD_ACTION_SUGGEST_DATES
      AutomaticProcessing::JulieActionsFlows::SuggestDates.new(self).trigger
    elsif self.action_nature == JD_ACTION_CHECK_AVAILABILITIES
      AutomaticProcessing::JulieActionsFlows::CheckAvailabilities.new(self).trigger
    elsif self.action_nature == JD_ACTION_WAIT_FOR_CONTACT
      AutomaticProcessing::JulieActionsFlows::WaitForContact.new(self).trigger
    elsif self.action_nature == JD_ACTION_SEND_CONFIRMATION
      AutomaticProcessing::JulieActionsFlows::SendConfirmation.new(self).trigger
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
end