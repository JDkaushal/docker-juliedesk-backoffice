class ApiController < ActionController::Base

  before_filter :authenticate_api, :set_headers_for_cross_domain

  protected
  def authenticate_api
    unless params[:access_key] == "678bdfbhjfHYDB78ndhdfbk98"
      render json: {
          status: "error",
          message: "Unauthorized"
      }
      return false
    end
    true
  end

  def set_headers_for_cross_domain
    headers['Access-Control-Allow-Origin'] = "*"
    headers['Access-Control-Request-Method'] = "*"
    headers['Access-Control-Allow-Headers'] = "*"
    headers['Access-Control-Allow-Credentials'] = "true"
  end


end
