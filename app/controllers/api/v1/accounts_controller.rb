class Api::V1::AccountsController < Api::ApiV1Controller

  def change_account_main_email
    Account.migrate_account_email(params[:old_email], params[:new_email])

    render json: {
               success: true
           }
  end
end