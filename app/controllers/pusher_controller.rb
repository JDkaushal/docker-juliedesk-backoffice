class PusherController < ApplicationController
  protect_from_forgery :except => :auth # stop rails CSRF protection for this action

  def auth
    if session[:user_name]
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id], {
          :user_id => session[:user_username], # => required
          :user_info => { # => optional - for example
                          :name => session[:user_name],
                          :email => session[:user_username]
          }
      })
      render json: response
    else
      render :text => "Forbidden", :status => '403'
    end
  end
end