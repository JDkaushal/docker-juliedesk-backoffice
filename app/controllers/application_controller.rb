class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  #protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

  before_filter :authenticate, :set_locale

  skip_before_action :verify_authenticity_token, only: :change_sound

  def change_sound
    session[:sound_is_activated] = false
    if params[:activated] == "true"
      session[:sound_is_activated] = true
    end

    render json: {
        status: "success",
        message: "",
        data: {}
    }
  end

  def logout
    email = session[:user_username]
    operator = Operator.find_by_email(email)
    MessagesThread.where(locked_by_operator_id: operator.id).update_all(locked_by_operator_id: nil)
    reset_session
    redirect_to "https://#{email}@juliedesk-backoffice.herokuapp.com"
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
    sound_is_activated = session[:sound_is_activated]
    reset_session
    authenticate_or_request_with_http_basic do |username, password|
      operator = Operator.find_by_email(username)
      if operator && operator.password_correct?(password)
        session[:operator_id] = operator.id
        session[:user_username] = operator.email
        session[:user_name] = operator.name
        session[:privilege] = operator.privilege

        session[:sound_is_activated] = sound_is_activated
        return true
      end

      false
    end
  end

  def only_admin
    if session[:privilege] == "admin"
      true
    else
      redirect_to "/"
      false
    end
  end
end
