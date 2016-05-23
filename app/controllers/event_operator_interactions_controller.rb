class EventOperatorInteractionsController < ApplicationController
  def create
    render json: EventOperatorInteraction.create({
                                        event_infos: params[:event_infos],
                                        modifications_done: params[:modifications_done],
                                        operator_id: session[:operator_id],
                                        done_at: Time.now
                                    })

  end
end
