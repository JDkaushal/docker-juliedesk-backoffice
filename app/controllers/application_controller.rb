class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :authenticate, :set_locale

  def omniauth_callback

    auth = request.env['omniauth.auth']
    render json: {
        message: "hello",
        data: auth["credentials"]
    }
  end

  protected

  def set_locale
    I18n.locale = :fr
  end
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "WePopp" && password == "popp2012jmm"
    end
  end
end
