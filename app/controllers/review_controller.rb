class ReviewController < ApplicationController
  before_filter :only_admin

  protected

  def only_admin
    if session[:privilege] == "admin"
      true
    else
      redirect_to "/"
      false
    end
  end
end
