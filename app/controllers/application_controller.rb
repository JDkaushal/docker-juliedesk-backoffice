class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.

  # protect_from_forgery with: :exception
  protect_from_forgery with: :null_session

  before_filter :authenticate, :set_locale
  before_action :check_rack_mini_profiler

  skip_before_action :verify_authenticity_token, only: :change_sound

  include FeatureHelper

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
    redirect_to "https://#{email}@#{request.env['HTTP_HOST']}"
  end

  # Add X-Request-ID to logs
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.uuid
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
      operator = Operator.find_by_email_and_enabled(username, true)

      if operator &&
          operator.password_correct?(password) &&
      (!operator.ips_whitelist_enabled || (ENV['IPS_WHITELIST'] || "").split(",").include?(request.remote_ip))

        session[:operator_id] = operator.id
        session[:user_username] = operator.email
        session[:user_name] = operator.name
        session[:privilege] = operator.privilege
        session[:planning_access] = operator.planning_access
        session[:can_see_operators_in_review] = operator.can_see_operators_in_review

        session[:sound_is_activated] = sound_is_activated
        return true
      end

      false
    end
  end

  def only_admin
    if session[:privilege] == Operator::PRIVILEGE_ADMIN
      true
    else
      redirect_to "/"
      false
    end
  end

  def only_admin_or_manager
    if session[:privilege] == Operator::PRIVILEGE_ADMIN || Operator.find(session[:operator_id]).manager_access
      true
    else
      redirect_to "/"
      false
    end
  end

  def only_super_operator_level_2_or_admin
    if session[:privilege] == Operator::PRIVILEGE_ADMIN ||
        session[:privilege] == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2
      true
    else
      redirect_to "/"
      false
    end
  end

  def check_staging_mode
    @staging_env = ENV['STAGING_APP'] == 'TRUE'
    @staging_target_email = ENV['STAGING_TARGET_EMAIL_ADDRESS']
    @staging_event_api_endpoint = ENV['STAGING_EVENT_API_ENDPOINT']
    @staging_calendar_login_email = ENV['STAGING_CALENDAR_LOGIN_EMAIL_ADDRESS']
  end

  def check_rack_mini_profiler
    if session[:privilege] == Operator::PRIVILEGE_ADMIN && "#{ENV['PERFORMANCES_PROFILERS']}".split(',').include?(session[:user_username])
      Rack::MiniProfiler.authorize_request
    end
  end
end
