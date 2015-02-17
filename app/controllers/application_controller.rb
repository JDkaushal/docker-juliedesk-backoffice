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
    if params[:locale] == "en"
      I18n.locale = :en
    else
      I18n.locale = :fr
    end
  end

  def authenticate
    authorized_users = [
        {
            username: "nicolas@juliedesk.com",
            name: "Nico",
            password: "popp2012jmm"
        },
        {
            username: "julien@juliedesk.com",
            name: "Julien",
            password: "popp2012jmm"
        },
        {
            username: "guillaume@juliedesk.com",
            name: "Guillaume",
            password: "popp2012jmm"
        },
        {
            username: "operator@juliedesk.com",
            name: "Other operator",
            password: "DareauJulieDesk2015"
        }
    ]

    authenticate_or_request_with_http_basic do |username, password|
      authenticated = false
      authorized_users.each do |user|
        if user[:username] == username && user[:password] == password
          session[:user_username] = user[:username]
          session[:user_name] = user[:name]
          authenticated = true
        end
      end
      authenticated
    end
  end
end
