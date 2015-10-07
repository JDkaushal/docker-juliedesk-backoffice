class Api::V1::MessagesThreadsController < Api::ApiV1Controller

  def inbox_count
    messages_threads = MessagesThread.where(in_inbox: true)
    accounts_cache = Account.accounts_cache(mode: "light")
    messages_threads.each{|mt| mt.account(accounts_cache: accounts_cache)}
    messages_threads = messages_threads.select{ |mt|
        !mt.delegated_to_founders &&
          mt.account &&
          !mt.account.only_admin_can_process
    }

    messages_threads = messages_threads.select do |mt|
      if mt.account.company_hash
        working_hours = mt.account.company_hash['working_hours']
        timezone = mt.account.company_hash['timezone']
        now = DateTime.now.in_time_zone(timezone)
        day = now.strftime("%a").downcase
        if working_hours[day]
          working_hours[day].select do |k, wh|
            hstart = wh[0].to_i
            hend = wh[1].to_i

            dstart = DateTime.now.in_time_zone(timezone).change({ hour: hstart/100, min: hstart%100, sec: 0 })
            dend = DateTime.now.in_time_zone(timezone).change({ hour: hend/100, min: hend%100, sec: 0 })
            now >= dstart && now <= dend
          end.length > 0
        else
          false
        end
      else
        true
      end
    end

    render json: {
        status: "success",
        data: {
            count: messages_threads.length
        }
    }
  end
end