class JulieActionsController < ApplicationController

  def show
    @julie_action = JulieAction.find params[:id]
    @message = @julie_action.message_classification.message
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(@julie_action.message_classification.message.messages_thread_id)
    @messages_thread.re_import
  end

  def update
    julie_action = JulieAction.find params[:id]

    date_times = []
    if params[:date_times]
      date_times = params[:date_times].map{|dt|
        {
            timezone: julie_action.message_classification.timezone,
            date: DateTime.parse(dt).utc.to_s
        }
      }
    end
    julie_action.update_attributes({
        text: params[:text],
        date_times: date_times.to_json,
        event_id: params[:event_id],
        calendar_id: params[:calendar_id],
        done: params[:done].present?,
        events: (params[:events].try(:values) || []).to_json,
        processed_in: params[:processed_in]
                                   })
    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end