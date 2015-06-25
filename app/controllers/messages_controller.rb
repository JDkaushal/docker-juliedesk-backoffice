class MessagesController < ApplicationController

  include ActionView::Helpers::TextHelper
  include ERB::Util

  def classifying
    @message = Message.find params[:id]
    @classification = params[:classification]

    if @classification == MessageClassification::UNKNOWN ||
        @classification == MessageClassification::ASK_INFO ||
        @classification == MessageClassification::ASK_CREATE_EVENT
      message_classification = @message.message_classifications.create_from_params classification: @classification, operator: session[:user_username], processed_in: (DateTime.now.to_i * 1000 - params[:started_at].to_i)
      redirect_to message_classification.julie_action
      return
    end

    if @classification == MessageClassification::TO_FOUNDERS
      @message.messages_thread.delegate_to_support message: params[:to_founders_message], operator: session[:user_name]
      redirect_to messages_threads_path
      return
    end

    if @classification == MessageClassification::CANCEL_TO_FOUNDERS
      @message.messages_thread.undelegate_to_support
      redirect_to messages_thread_path(@message.messages_thread)
      return
    end

    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(@message.messages_thread_id)
    @messages_thread.re_import
    @message = @messages_thread.messages.select{|m| m.id == @message.id}.first

    if @classification == MessageClassification::ASSOCIATE_EVENT
      #|| @classification == MessageClassification::GIVE_PREFERENCE
      render "classifying_admin" and return
    end
  end

  def wait_for_preference_change
    message = Message.find params[:id]

    message.messages_thread.delegate_to_support

    url = "https://juliedesk-app.herokuapp.com/api/v1/accounts/wait_for_preferences_change"
    x = Net::HTTP.post_form(URI.parse(url), {
        email: message.messages_thread.account_email,
        access_key: "gho67FBDJKdbhfj890oPm56VUdfhq8"
    })

    redirect_to :messages_threads
  end

  def classify
    message = Message.find(params[:id])
    params[:operator] = session[:user_username]
    message_classification = message.message_classifications.create_from_params params

    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now - ((params[:processed_in] || "0").to_i / 1000).seconds,
                                         target: message_classification,
                                         nature: OperatorAction::NATURE_OPEN,
                                         operator_id: session[:operator_id],
                                         messages_thread_id: message.messages_thread_id
                                     })

    if message_classification.classification == MessageClassification::GIVE_PREFERENCE
      url = "https://juliedesk-app.herokuapp.com/api/v1/accounts/set_awaiting_current_notes"

      Net::HTTP.post_form(URI.parse(url), {
          email: message.messages_thread.account_email,
          awaiting_current_notes: "#{params[:awaiting_current_notes]} (message_thread id: #{message.messages_thread_id})",
          access_key: "gho67FBDJKdbhfj890oPm56VUdfhq8"
      })
    end

    render json: {
        status: "success",
        message: "",
        redirect_url: julie_action_path(message_classification.julie_action),
        data: {}
    }
  end

  def generate_threads
    message = Message.find params[:id]

    message.delay.generate_threads((params[:julie_messages] || {}).values)

    render json: {
        status: "success",
        message: "",
        data: {}
    }
  end

  def reply
    @message = Message.find params[:id]

    html_message = "#{text_to_html(params[:text])} #{params[:html_signature]}"
    text_message = "#{params[:text]}#{strip_tags(params[:html_signature])}"

    response_message = @message.google_message.reply_all_with(Gmail::Message.new({text: text_message, html: html_message}))

    response_message.to = (params[:to] || []).join(", ")
    response_message.cc = (params[:cc] || []).join(", ")

    unless params[:quote_message] == "true"
      response_message.text = text_message
      response_message.html = html_message
      response_message.body = nil
    end

    julie_alias = @message.messages_thread.julie_alias
    response_message.from = julie_alias.generate_from
    response_message_sent = response_message.deliver

    p "*" * 50
    p response_message_sent


    julie_action = JulieAction.find params[:julie_action_id]
    julie_action.update_attribute :google_message_id, response_message_sent.id

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end

  def mark_as_read
    message = Message.find params[:id]
    message.google_message.mark_as_read

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end

  def get_attachment
    message = Message.find params[:id]
    google_message = message.google_message

    result = Gmail.request(Gmail.service.users.to_h['gmail.users.messages.attachments.get'], {
        messageId: google_message.id,
        id: params[:attachment_id]
    })

    send_data Base64.decode64(result[:data].gsub("-", "+").gsub("_", "/")),
              :type => params[:format], :disposition => 'inline'
  end

  private

  def text_to_html text
      text.split("\n").map{|line| "<div>#{(line.present?)?h(line):"<br>"}</div>"}.join("\n").html_safe
  end

end
