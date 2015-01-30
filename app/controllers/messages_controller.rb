class MessagesController < ApplicationController

  include ActionView::Helpers::TextHelper
  include ERB::Util

  def classifying
    @message = Message.find params[:id]
    @classification = params[:classification]
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(@message.messages_thread_id)

    if @classification == MessageClassification::UNKNOWN ||
        @classification == MessageClassification::ASK_INFO
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

  def reply
    @message = Message.find params[:id]

    response_message = @message.google_message.reply_all_with(Gmail::Message.new({text: params[:text], html: h(simple_format(params[:text]))}))

    response_message.to = (params[:to] || []).join(", ")
    response_message.cc = (params[:cc] || []).join(", ")
    response_message.deliver

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end

end
