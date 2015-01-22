class JulieActionsController < ApplicationController

  def update
    julie_action = JulieAction.find params[:id]
    julie_action.update_attributes({
        text: params[:text],
        date_times: params[:date_times].to_json
                                   })
    render json: {
        status: "success",
        message: "",
        data: {

        }
    }
  end
end