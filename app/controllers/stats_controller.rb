class StatsController < ApplicationController

  layout "stats"
  def index

    accounts = Account.get_active_account_emails
    accounts.select!{|account|
      !%w"julien@wepopp.com nmarlier@gmail.com nicolas@wepopp.com nicolas.marlier@wanadoo.fr nicolas@marlier.onmicrosoft.com mboimada@gmail.com".include? account
    }
    message_threads = MessagesThread.all.group_by(&:account_email)

    last_month = [DateTime.now.beginning_of_month, DateTime.now.end_of_month]
    @months = (-2..0).map{|i|
      last_month.map{|dt| dt + i.months}
    }

    @data = Hash[accounts.map do |account|
      [account, @months.map{|month|

        (message_threads[account] || []).select{|mt|
          mt.created_at >= month[0] && mt.created_at < month[1]
        }.length
      }]
      end].sort_by{|account, counts| -(counts.sum)}
    end
end