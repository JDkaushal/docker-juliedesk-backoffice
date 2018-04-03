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