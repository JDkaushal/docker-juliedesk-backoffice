class Api::V1::AccountsController < Api::ApiV1Controller

  def change_account_main_email
    #AccountEmailMigrationWorker.enqueue(params[:old_email], params[:new_email])
    #Account.migrate_account_email(params[:old_email], params[:new_email])

    render json: {
             success: AccountEmailMigrationWorker.enqueue(params[:old_email], params[:new_email])
           }
  end

  def account_gone_unsubscribed
    AccountFlows::ClientUnsubscribed.new(params[:account_email]).trigger
    render json: { status: "success" }
  end

  def compute_requests_count
    if params[:detailed]
      data = Account.requests_count(params[:account_emails], DateTime.parse(params[:from_date]), DateTime.parse(params[:to_date]), detailed: true)
    else
      data =  {
          count: Account.requests_count(params[:account_emails], DateTime.parse(params[:from_date]), DateTime.parse(params[:to_date]))
      }
    end

    render json: {
        status: 'success',
        data: data
    }
  end
end