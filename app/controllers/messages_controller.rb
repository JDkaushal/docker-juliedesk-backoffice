class MessagesController < ApplicationController

  include ActionView::Helpers::TextHelper
  include ERB::Util

  def classifying
    @message = Message.find params[:id]
    @classification = params[:classification]

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten

    if @classification == MessageClassification::FORWARD_TO_CLIENT ||
        @classification == MessageClassification::UNKNOWN ||
        @classification == MessageClassification::ASK_INFO ||
        @classification == MessageClassification::ASK_CREATE_EVENT
      message_classification = @message.message_classifications.create_from_params classification: @classification, operator: session[:user_username], processed_in: (DateTime.now.to_i * 1000 - params[:started_at].to_i)
      redirect_to message_classification.julie_action
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

    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(@message.messages_thread_id)
    @messages_thread.re_import
    @message = @messages_thread.messages.select{|m| m.id == @message.id}.first

  end

  def classify
    @message = Message.find(params[:id])
    params[:operator] = session[:user_username]
    @message_classification = @message.message_classifications.create_from_params params

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now - ((params[:processed_in] || "0").to_i / 1000).seconds,
                                         target: @message_classification,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: @message.messages_thread_id
                                     })

    if @message_classification.classification == MessageClassification::GIVE_PREFERENCE
      url = "https://juliedesk-app.herokuapp.com/api/v1/accounts/set_awaiting_current_notes"

      Net::HTTP.post_form(URI.parse(url), {
          email: @message.messages_thread.account_email,
          awaiting_current_notes: "#{params[:awaiting_current_notes]} (message_thread id: #{@message.messages_thread_id})",
          access_key: "gho67FBDJKdbhfj890oPm56VUdfhq8"
      })
    end

    render json: {
        status: "success",
        message: "",
        redirect_url: julie_action_path(@message_classification.julie_action),
        data: {}
    }
  end

  def generate_threads
    p "*" * 50
    p "Generating threads..."
    @message = Message.find params[:id]
    p "Found message. genrates threads"
    @message.generate_threads((params[:julie_messages] || {}).values)
    p "Done."
    p "*" * 50
    render json: {
        status: "success",
        message: "",
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

    @new_server_message_id = EmailServer.deliver_message({
      subject: params[:subject],
      from: @julie_alias.generate_from,
      to: (params[:to] || []).join(", "),
      cc: (params[:cc] || []).join(", "),
      text: "#{params[:text]}#{strip_tags(params[:html_signature])}",
      html: "#{text_to_html(params[:text])} #{params[:html_signature]}",
      quote_replied_message: quote_replied_message,
      quote_forward_message: quote_forward_message,
      reply_to_message_id:  @message.server_message_id
    })['id']

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
