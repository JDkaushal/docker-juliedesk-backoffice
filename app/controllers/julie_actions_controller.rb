class JulieActionsController < ApplicationController

  def show
    @julie_action = JulieAction.find params[:id]
    @message = @julie_action.message_classification.message
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(@julie_action.message_classification.message.messages_thread_id)
  end

  def update
    julie_action = JulieAction.find params[:id]
    julie_action.update_attributes({
        text: params[:text],
        date_times: (params[:date_times] || []).to_json,
        event_ids: (params[:event_ids] || []).to_json,
        done: params[:done].present?,
        processed_in: params[:processed_in]
                                   })
    if julie_action.done
      julie_action.message.google_message.archive
    end
    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end