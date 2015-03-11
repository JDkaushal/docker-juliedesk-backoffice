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

  def volume
    message_threads = MessagesThread.all.includes(messages: :message_classifications)
    messages = message_threads.map(&:messages).flatten
    last_day = [DateTime.now.beginning_of_day, DateTime.now.end_of_day]
    @days = (-30..0).map{|i|
      last_day.map{|dt| dt + i.days}
    }
    @data = {}
    @data[:message_threads] = @days.map{|day|
        message_threads.select{|mt|
          mt.created_at >= day[0] && mt.created_at < day[1]
        }.length
      }

    @data[:messages] = @days.map{|day|
      messages.select{|mt|
        mt.received_at >= day[0] && mt.received_at < day[1] && mt.message_classifications.length > 0
      }.length
    }
  end
end