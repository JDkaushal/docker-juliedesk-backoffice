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

  def autocomplete
    all_accounts_by_alias = Account.get_active_account_emails(detailed: true).map do |account|
      ((account['email_aliases'] || []) + [nil]).map do |email_alias|
        {
            email: account['email'],
            name: account['full_name'],
            company: account['company_hash'].try(:[], 'name'),
            email_alias: email_alias
        }
      end
    end.flatten

    accounts = all_accounts_by_alias.select do |account|
      account.to_json.downcase.include? "#{params[:request]}".downcase
    end.uniq do |account|
      account[:email]
    end.first(5)

    render json: {
        status: "success",
        data: accounts
    }
  end

end
