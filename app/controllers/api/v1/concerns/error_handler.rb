module Api::V1::Concerns::ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Exception, with: :error_handler
  end

  private

  def error_handler(error)
    case error
      when Api::InvalidParamsException
        render json: { error_code: "INVALID_PARAMS", message: "the supplied params are invalid", details: error.errors }, status: :unprocessable_entity
      else
        raise error
    end
  end

end