class Api::V1::MessagesController < Api::ApiV1Controller

  def simulate_classify
    message = Message.find(params[:id])
    message_classification = AutomaticProcessing::Processor.new(message.id, dup_message: true).generate_classification

    data = {
        message_id:               message.id,
        server_message_id:        message.server_message_id,
        message_interpretations:  message_classification.message.message_interpretations,
        message_classification:   message_classification
    }

    render json: data, status: :ok
  end

end