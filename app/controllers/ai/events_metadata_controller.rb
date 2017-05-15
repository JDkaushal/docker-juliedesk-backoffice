class Ai::EventsMetadataController < ApplicationController

  def fetch
    render json: AI_PROXY_INTERFACE.build_request(:calendar_classification, {calendar: params[:events], calendar_login_username: params[:calendar_login_username]})
  rescue AiProxy::TimeoutError
      render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

end