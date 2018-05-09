class AutomaticProcessing::AutomatedJulieAction < JulieAction
  self.table_name = "automated_julie_actions"

  belongs_to :message_classification, class_name: "AutomaticProcessing::AutomatedMessageClassification"

  include TemplateGeneratorHelper
  include ApplicationHelper

  def initialize(params = {})
    super(params)
  end

  def self.from_julie_action(julie_action)
    AutomaticProcessing::AutomatedJulieAction.new(julie_action.attributes.reject{ |k,_| ['id', 'created_at', 'updated_at'].include?(k) })
  end

  def process(options = {})
    raise AutomaticProcessing::Exceptions::NoMessageClassificationProvidedError if self.message_classification.nil?

    if self.action_nature == JD_ACTION_SUGGEST_DATES
      AutomaticProcessing::JulieActionsFlows::SuggestDates.new(self).trigger(options[:suggest_again])
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