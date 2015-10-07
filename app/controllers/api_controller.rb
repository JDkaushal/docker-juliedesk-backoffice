class ApiController < ActionController::Base

  before_filter :authenticate

  def authenticate
    unless params[:access_key] == "EDx19D72bH7e5I64EXk1kwa4jXvynddS"
      render json: {
          status: "error",
          message: "Authentication problem"
      }, code: 401
      false
    end
    true
  end
end