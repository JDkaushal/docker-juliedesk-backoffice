class MessagesController < ApplicationController

  include ActionView::Helpers::TextHelper
  include ERB::Util
  include ProfilerHelper

  before_action :check_staging_mode


  def classifying

    @message = Message.find params[:id]
    @classification = params[:classification]

    @display_calendar = @classification == MessageClassification::GIVE_INFO || @classification == MessageClassification::UPDATE_EVENT

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.select { |_, account| account['subscribed'] && account['configured'] }.map{|_, account| [account['email']] + account['email_aliases']}.flatten.map(&:downcase)


    if @classification == MessageClassification::FORWARD_TO_CLIENT ||
        @classification == MessageClassification::UNKNOWN ||
        @classification == MessageClassification::FORWARD_TO_SUPPORT ||
        @classification == MessageClassification::ASK_INFO ||
        @classification == MessageClassification::ASK_CREATE_EVENT
      message_classification = @message.message_classifications.create_from_params classification: @classification, operator: session[:user_username], processed_in: (DateTime.now.to_i * 1000 - params[:started_at].to_i)
      redirect_to julie_action_path(message_classification.julie_action, default_template: params[:default_template])
      return
    end

    if @classification == MessageClassification::TO_FOUNDERS
      delegation_message = params[:to_admin_message]
      @message.messages_thread.send_to_admin message: delegation_message, operator: session[:user_name]

      OperatorAction.create_and_verify({
                                           initiated_at: DateTime.now,
                                           target: @message.messages_thread,
                                           nature: OperatorAction::NATURE_SEND_TO_SUPPORT,
                                           operator_id: session[:operator_id],
                                           messages_thread_id: @message.messages_thread_id,
                                           message: delegation_message
                                       })

      redirect_to messages_threads_path
      return
    end

    if @classification == MessageClassification::CANCEL_TO_FOUNDERS
      @message.messages_thread.undelegate_to_admin
      redirect_to messages_thread_path(@message.messages_thread)
      return
    end

    if @classification == MessageClassification::CANCEL_TO_SUPPORT
      @message.messages_thread.undelegate_to_support
      redirect_to messages_thread_path(@message.messages_thread)
      return
    end

    if @classification == MessageClassification::FOLLOW_UP_CLIENT
      message_classification = @message.message_classifications.create_from_params classification: @classification, operator: session[:user_username], processed_in: (DateTime.now.to_i * 1000 - params[:started_at].to_i)
      redirect_to julie_action_path(message_classification.julie_action)
      return
    end

    if params[:ignore_linked_attendees]
      last_classif = @message.message_classifications.last
      new_classif = last_classif.dup
      new_classif.assign_attributes(classification: @classification, operator: session[:user_username], processed_in: (DateTime.now.to_i * 1000 - params[:started_at].to_i))
      new_classif.ignore_linked_attendees = true
      new_classif.save
      new_classif.append_julie_action
      redirect_to julie_action_path(new_classif.julie_action)
      return
    end

    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action, message_interpretations: {}}).find(@message.messages_thread_id)
    @messages_thread.re_import

    @message = @messages_thread.messages.select{|m| m.id == @message.id}.first

  rescue ActiveRecord::RecordNotFound => e
    render status: :not_found, text: 'Sorry, this message does not exists.'
  end

  def let_ai_process
    begin
      AutomaticProcessing::AutomatedMessageClassification.process_message_id(params[:id])
      render json: { status: 'success' }
    rescue Exception => e
      render json: { status: 'error', message: e.to_s }
    end
  end

  def main_interpretation
    message = Message.find params[:id]

    render json: {
        status: 'success',
        data: {
            interpretation: message.main_message_interpretation.try(:json_response) || {}
        }
    }
  end

  def classify
    params.permit!
    initiated_time = Time.now

    @message = Message.find(params[:id])
    params[:operator] = session[:user_username]

    messages_thread = @message.messages_thread

    messages_thread_params = {last_operator_id: session[:operator_id]}
    messages_thread_params.merge!(event_booked_date: params[:event_booked_date]) if params[:event_booked_date].present?
    messages_thread.update(messages_thread_params)
    messages_thread.check_recompute_linked_attendees(params[:old_attendees], params[:attendees])

    data = params.to_h.merge({messages_thread_id: @message.messages_thread_id}).with_indifferent_access
    @message_classification = @message.message_classifications.create_from_params(data)
    @message_classification.julie_action.update_initial_attributes(params)

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now - ((params[:processed_in] || '0').to_i / 1000).seconds,
                                         target: @message_classification,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: @message.messages_thread_id
                                     })
    if @message_classification.classification == MessageClassification::GIVE_PREFERENCE

      ADMIN_API_INTERFACE.build_request(:set_awaiting_current_notes, {
          email: @message.messages_thread.account_email,
          awaiting_current_notes: "#{params[:awaiting_current_notes]} (review link: #{ENV['BACKOFFICE_BASE_URL']}/review/messages_threads/#{@message.messages_thread_id}/review)"
      })

    end



    JuliedeskTrackerInterface.new.build_request(:track, {name: 'Auto_suggestions_tracking', date:  initiated_time.to_s, properties: {step: 'messages#classify:initiated', julie_action_id: @message_classification.julie_action.id}, distinct_id: @message_classification.julie_action.id})
    JuliedeskTrackerInterface.new.build_request(:track, {name: 'Auto_suggestions_tracking', date:  Time.now.to_s, properties: {step: 'messages#classify:done', julie_action_id: @message_classification.julie_action.id}, distinct_id: @message_classification.julie_action.id})

    render json: {
        status: 'success',
        message: '',
        redirect_url: julie_action_path(@message_classification.julie_action),
        data: {}
    }
  end

  def generate_threads
    @message = Message.find params[:id]
    @message.generate_threads((params[:julie_messages] || {}).values)

    render json: {
        status: "success",
        message: "",
        data: {}
    }
  end

  def generate_threads_for_follow_up
    (params[:follow_up_data] || {}).values.each do |follow_up_item|
      GenerateFollowUpWorker.enqueue(follow_up_item['messages_thread_id'], follow_up_item['message'], session[:operator_id])
    end

    render json: {
        status: "success",
        data: {}
    }
  end

  def reply
    @message = Message.find params[:id]

    @julie_alias = JulieAlias.find_by_email(params[:from]) #|| JulieAlias.find_by_email(ENV['DEFAULT_JULIE_ALIAS_EMAIL'])

    if @julie_alias.blank?
      raise JulieAlias::JulieAliasNotFoundError.new("Julie alias with email #{params[:from]} was not found")
    end

    quote_replied_message = false
    quote_forward_message = false

    if params[:forward] == 'true'
      quote_forward_message = true
    elsif params[:quote_message] == 'true'
      quote_replied_message = true
    end

    email_params = {
        from: @julie_alias.generate_from,
        to: (params[:to] || []).join(", "),
        cc: (params[:cc] || []).join(", "),
        text: "#{params[:text]}#{strip_tags(params[:html_signature])}",
        html: params[:html].present? ? params[:html] : "#{(text_to_html(params[:text]))} #{params[:html_signature]}",
        quote_replied_message: quote_replied_message,
        quote_forward_message: quote_forward_message,
        reply_to_message_id:  @message.server_message_id
    }

    if ENV['STAGING_APP']
      email_params.merge!(message_thread_id: @message.messages_thread_id, server_thread_id: @message.messages_thread.server_thread_id)
    end

    begin
      @new_server_message_id = EmailServer.deliver_message(email_params)['id']
    rescue Exception => e
      Raven.capture_exception(e) unless ENV['SENTRY_DSN'].nil?
      render json: {
                 status: "error",
                 message: e.message,
             }, status: 400 and return
    end


    RequestAtWorker.enqueue @message.messages_thread.id

    # We set should follow up to false when we send the email
    @message.messages_thread.update(should_follow_up: false)

    @julie_action = JulieAction.find params[:julie_action_id]
    @julie_action.update_attribute :server_message_id, @new_server_message_id


    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end

  private

    def text_to_html text
        text.split("\n").map{|line| "<div>#{(line.present?)?h(line):"<br>"}</div>"}.join("\n").html_safe
    end

end
