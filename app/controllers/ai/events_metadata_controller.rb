class Ai::EventsMetadataController < ApplicationController

  def fetch
    render json: AiProxy.new.build_request(:calendar_classification, {calendar: params[:events], calendar_login_username: params[:calendar_login_username]})
  end

end