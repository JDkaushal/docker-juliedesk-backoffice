class MessagesController < ApplicationController

  include ActionView::Helpers::TextHelper
  include ERB::Util

  def classifying
    @message = Message.find params[:id]
    @classification = params[:classification]
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(@message.messages_thread_id)
    @messages_thread.re_import

    if @classification == MessageClassification::UNKNOWN ||
        @classification == MessageClassification::ASK_INFO ||
        @classification == MessageClassification::ASK_CANCEL_APPOINTMENT ||
        @classification == MessageClassification::ASK_CANCEL_EVENTS ||
        @classification == MessageClassification::ASK_POSTPONE_EVENTS
      message_classification = @message.message_classifications.create_from_params classification: @classification, operator: session[:user_username], processed_in: (DateTime.now.to_i * 1000 - params[:started_at].to_i)
      redirect_to message_classification.julie_action
    end
  end

  def classify
    message = Message.find(params[:id])
    params[:operator] = session[:user_username]
    message_classification = message.message_classifications.create_from_params params

    render json: {
        status: "success",
        message: "",
        redirect_url: julie_action_path(message_classification.julie_action),
        data: {}
    }
  end

  def generate_threads
    message = Message.find params[:id]

    message.generate_threads (params[:julie_messages] || {}).values

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
    response_message.from = "#{JULIE_ALIASES_DATA[julie_alias][:name]} <#{julie_alias}>"
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

  private

  def text_to_html text
      text.split("\n").map{|line| "<div>#{(line.present?)?h(line):"<br>"}</div>"}.join("\n").html_safe
  end

end
