class Api::EventsController < ApiController


  def classified_events
    events = Event.where(email: params[:email]).where("classification IS NOT NULL")

    render json: {
        status: "success",
        message: "",
        data: Hash[events.map{|event| [event.event_id, event.classification]}]
    }
  end


end
