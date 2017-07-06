class Ai::DatesVerificationController < ApplicationController

  def verify_dates
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates, params)
    rescue AiProxy::TimeoutError
      render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_v2
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v2, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end
end