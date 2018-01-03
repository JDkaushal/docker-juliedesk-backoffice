class Ai::DatesVerificationController < ApplicationController

  def verify_dates_v8
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v8, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_v9
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v9, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_v10
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v10, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_v11
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v11, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_with_version
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_versioned, params)
  rescue
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end
end