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
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten.map(&:downcase)

    begin
      open_thread_date = begin
        DateTime.strptime(params[:started_at], "%s").strftime("%Y-%m-%dT%H:%M:%S")
        rescue
          nil
      end
    ClientSuccessTrackingHelpers.async_track("julie_action", @message.messages_thread.account_email, {
        bo_thread_id:  @message.messages_thread_id,
        bo_message_id:  @message.id,
        thread_messages_count:  @message.messages_thread.messages.count,
        current_classification: @classification,
        new_email_received_date: @message.created_at.strftime("%Y-%m-%dT%H:%M:%S"),
        thread_is_open_date: open_thread_date,
        thread_status: @message.messages_thread.status,
        first_time: @message.messages_thread.messages.map(&:message_classifications).flatten.length <= 1
    })
    rescue
    end


    if @classification == MessageClassification::FORWARD_TO_CLIENT ||
        @classification == MessageClassification::UNKNOWN ||
        @classification == MessageClassification::FORWARD_TO_SUPPORT ||
        @classification == MessageClassification::ASK_INFO ||
        @classification == MessageClassification::ASK_CREATE_EVENT
      message_classification = @message.message_classifications.create_from_params classification: @classification, operator: session[:user_username], processed_in: (DateTime.now.to_i * 1000 - params[:started_at].to_i)
      redirect_to julie_action_path(message_classification.julie_action)
      return
    end

    if @classification == MessageClassification::TO_FOUNDERS
      delegation_message = params[:to_founders_message]
      @message.messages_thread.delegate_to_founders message: delegation_message, operator: session[:user_name]

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
      @message.messages_thread.undelegate_to_founders
      redirect_to messages_thread_path(@message.messages_thread)
      return
    end

    if @classification == MessageClassification::CANCEL_TO_SUPPORT
      @message.messages_thread.undelegate_to_support
      redirect_to messages_thread_path(@message.messages_thread)
      return
    end

    if @classification == MessageClassification::FOLLOW_UP_CONTACTS || @classification == MessageClassification::FOLLOW_UP_CLIENT
      message_classification = @message.message_classifications.create_from_params classification: @classification, operator: session[:user_username], processed_in: (DateTime.now.to_i * 1000 - params[:started_at].to_i)
      redirect_to julie_action_path(message_classification.julie_action)
      return
    end

    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action, message_interpretations: {}}).find(@message.messages_thread_id)
    @messages_thread.re_import

    @message = @messages_thread.messages.select{|m| m.id == @message.id}.first
  end

  def classify
    @message = Message.find(params[:id])
    params[:operator] = session[:user_username]

    @message_classification = @message.message_classifications.create_from_params params.merge({messages_thread_id: @message.messages_thread_id})
    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now - ((params[:processed_in] || "0").to_i / 1000).seconds,
                                         target: @message_classification,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: @message.messages_thread_id
                                     })
    if @message_classification.classification == MessageClassification::GIVE_PREFERENCE
      http = HTTP.auth(ENV['JULIEDESK_APP_API_KEY'])

      http.post("#{ENV['JULIEDESK_APP_BASE_PATH']}/api/v1/accounts/set_awaiting_current_notes", json: {
                                                                                                    email: @message.messages_thread.account_email,
                                                                                                    awaiting_current_notes: "#{params[:awaiting_current_notes]} (review link: https://juliedesk-backoffice.herokuapp.com/review/messages_threads/#{@message.messages_thread_id}/review)"
                                                                                                })

      # client = HTTPClient.new(default_header: {
      #                             "Authorization" => ENV['JULIEDESK_APP_API_KEY']
      #                         })
      # client.post("https://juliedesk-app.herokuapp.com/api/v1/accounts/set_awaiting_current_notes", {
      #                    email: @message.messages_thread.account_email,
      #                    awaiting_current_notes: "#{params[:awaiting_current_notes]} (message_thread id: #{@message.messages_thread_id})"
      #                })
    end
    messages_thread_params = {last_operator_id: session[:operator_id]}
    messages_thread_params.merge!(event_booked_date: params[:event_booked_date]) if params[:event_booked_date].present?
    @message.messages_thread.update(messages_thread_params)
    render json: {
        status: "success",
        message: "",
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
      messages_thread = MessagesThread.find follow_up_item['messages_thread_id']
      messages_thread.update_attributes(should_follow_up: true, follow_up_instruction: follow_up_item['message'])

      OperatorAction.create({
                                      initiated_at: DateTime.now,
                                      target: messages_thread,
                                      nature: OperatorAction::NATURE_OPEN,
                                      operator_id: session[:operator_id],
                                      messages_thread_id: messages_thread.id
                                  })
      OperatorAction.create_and_verify({
                                           initiated_at: DateTime.now,
                                           target: messages_thread,
                                           nature: OperatorAction::NATURE_SEND_TO_SUPPORT,
                                           operator_id: session[:operator_id],
                                           messages_thread_id: messages_thread.id,
                                           message: "#FollowUp #{follow_up_item['message']}"
                                       })
    end

    render json: {
        status: "success",
        data: {}
    }
  end

  def reply
    @message = Message.find params[:id]

    @julie_alias = JulieAlias.find_by_email(params[:from]) || JulieAlias.find_by_email("julie@juliedesk.com")

    quote_replied_message = false
    quote_forward_message = false
    if params[:forward] == "true"
      quote_forward_message = true
    elsif params[:quote_message] == "true"
      quote_replied_message = true
    end

    email_params = {
        subject: params[:subject],
        from: @julie_alias.generate_from,
        to: (params[:to] || []).join(", "),
        cc: (params[:cc] || []).join(", "),
        text: "#{params[:text]}#{strip_tags(params[:html_signature])}",
        html: "#{text_to_html(params[:text])} #{params[:html_signature]}",
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
