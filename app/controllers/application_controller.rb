class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  #protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

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
    if params[:locale] == "en"
      I18n.locale = :en
    else
      I18n.locale = :fr
    end
  end

  def authenticate

    reset_session
    authenticate_or_request_with_http_basic do |username, password|
      operator = Operator.find_by_email(username)
      if operator && operator.password_correct?(password)
        session[:user_username] = operator.email
        session[:user_name] = operator.name
        session[:privilege] = operator.privilege
        return true
      end

      false
    end
  end
end
