class MessagesController < ApplicationController

  include ActionView::Helpers::TextHelper
  include ERB::Util

  def classify
    message = Message.find(params[:id])
    message.message_classifications.delete_all
    message.julie_actions.delete_all

    message.message_classifications.create_from_params params
    message = Message.find(params[:id])
    message.validate_message_classifications

    render json: {
        status: "success",
        message: "",
        redirect_url: url_for(action: :process_actions),
        data: {}
    }
  end

  def process_actions
    @message = Message.find(params[:id])
    @action = @message.julie_actions.last
  end

  def next_to_classify
    message = MessagesThread.where(in_inbox: true).includes(messages: :message_classifications).map(&:messages_to_classify).flatten.sort_by(&:received_at).first
    if message
      redirect_to action: :show, id: message.id
    else
      redirect_to controller: :messages_threads, action: :index
    end
  end

  def show
    @message = Message.find params[:id]
  end

  def classifying
    @message = Message.find params[:id]
    @classification = params[:classification]

    if @classification == MessageClassification::UNKNOWN
      @message.message_classifications.create classification: @classification
      redirect_to action: :next_to_classify
    elsif @classification == MessageClassification::ASK_AND_GIVE_NOTHING
      @message.message_classifications.create classification: @classification
      @message.google_message.archive
      redirect_to action: :next_to_classify
    elsif @classification == MessageClassification::ASK_INFO
      @message.message_classifications.create classification: @classification
      @message.validate_message_classifications
      redirect_to action: :process_actions
    end

  end

  def reply
    @message = Message.find params[:id]

    response_message = @message.google_message.reply_all_with(Gmail::Message.new({text: params[:text], html: h(simple_format(params[:text]))}))

    response_message.deliver

    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end
