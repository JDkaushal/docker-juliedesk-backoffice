class AccountsController < ApplicationController

  before_action :check_staging_mode


  def show
    account = Account.create_from_email(params[:email])
    if account

      render json: {
          status: "success",
          data: {
              account: account
          }
      }
    else
      render json: {
          status: "error",
          message: "No account with email #{params[:email]}"
      }, status: 404
    end
  end

end
