class EventsController < ApplicationController

  def index
    events = Event.where(classification: nil)

    if events.empty?
      redirect_to action: :index
    else
      redirect_to action: :show, id: events.first.id
    end
  end

  def show
    @event = Event.find params[:id]
    @event_data = @event.fetch
  end

  def classify
    @event = Event.find params[:id]
    @event.update_attribute :classification, params[:classification]
    events = Event.where(classification: nil)

    if events.empty?
      redirect_to "/"
    else
      redirect_to action: :show, id: events.first.id
    end

  end
end
