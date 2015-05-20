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
    end

    if @classification == MessageClassification::TO_FOUNDERS
      @message.messages_thread.update_attributes({
                                                     delegated_to_founders: true,
                                                     to_founders_message: params[:to_founders_message]
                                                 })
      @message.messages_thread.google_thread.modify(["Label_12"], [])
      redirect_to messages_threads_path
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
    url = "https://juliedesk-app.herokuapp.com/api/v1/accounts/wait_for_preferences_change"

    message.messages_thread.update_attribute :delegated_to_founders, true
    message.messages_thread.google_thread.modify(["Label_12"], [])

    x = Net::HTTP.post_form(URI.parse(url), {
        email: message.messages_thread.account_email,
        access_key: "gho67FBDJKdbhfj890oPm56VUdfhq8"
    })

    p "*" * 50
    p x.body

    redirect_to :messages_threads
  end

  def classify
    message = Message.find(params[:id])
    params[:operator] = session[:user_username]
    message_classification = message.message_classifications.create_from_params params

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

    p "*" * 50
    unless params[:quote_message] == "true"
      p "should not quote"
      response_message.text = text_message
      response_message.html = html_message
      response_message.body = nil
    end

    julie_alias = @message.messages_thread.julie_alias
    response_message.from = julie_alias.generate_from
    response_message.deliver

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
