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

  def verify_dates_v3
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v3, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_v4
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v4, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_v5
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v5, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_v6
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v6, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

  def verify_dates_v7
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_v7, params)
  rescue AiProxy::TimeoutError
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end

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

  def verify_dates_with_version
    render json: AI_PROXY_INTERFACE.build_request(:verify_dates_versioned, params)
  rescue
    render json: { error_code: "AI_TIMEOUT", message: "Timeout error" }, status: :request_timeout
  end
end