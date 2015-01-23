class JulieActionsController < ApplicationController

  def update
    julie_action = JulieAction.find params[:id]
    julie_action.update_attributes({
        text: params[:text],
        date_times: (params[:date_times] || []).to_json,
        event_ids: (params[:event_ids] || []).to_json,
        done: params[:done].present?
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