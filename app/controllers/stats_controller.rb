class StatsController < ApplicationController

  layout "stats"
  def index

    accounts = Account.get_active_account_emails
    accounts.select!{|account|
      !%w"julien@wepopp.com nmarlier@gmail.com nicolas@wepopp.com nicolas.marlier@wanadoo.fr nicolas@marlier.onmicrosoft.com mboimada@gmail.com".include? account
    }
    message_threads = MessagesThread.all.includes(messages: {message_classifications: {julie_action: {}}}).group_by(&:account_email)

    last_month = [DateTime.now.beginning_of_month, DateTime.now.end_of_month]
    @months = (-2..0).map{|i|
      last_month.map{|dt| dt + i.months}
    }

    @data = Hash[accounts.map do |account|
      [account, @months.map{|month|
        mcs = (message_threads[account] || []).map(&:messages).flatten.map(&:message_classifications).flatten.select{|mc|
          mc.updated_at >= month[0] && mc.updated_at < month[1]
        }
        jas = {
            "message threads" => (message_threads[account] || []).select{|mt|
              mt.created_at >= month[0] && mt.created_at < month[1]
            }.length,
            "messages" => (message_threads[account] || []).map(&:messages).flatten.select{|m|
              m.received_at >= month[0] && m.received_at < month[1]
            }.length - mcs.length,
            "actions" => mcs.length,
            "hours" => ((mcs.map(&:processed_in).compact.sum + mcs.map(&:julie_action).map(&:processed_in).compact.sum) * 10 / 1000 / 3600) / 10.0
        }

      }]
      end].sort_by{|account, counts| -(counts.map{|c| c.values.first}.sum)}
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