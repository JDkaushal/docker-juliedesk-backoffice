module ApplicationHelper


  def self.hash_from_parenthesized_contact contact
    {
        email: contact.split(" ").last.gsub("(", "").gsub(")", ""),
        name: self.strip_contact_name(contact)
    }
  end
  def self.strip_email contact
    begin
      ApplicationHelper.find_addresses(contact).addresses.first.address
    rescue
      nil
    end
  end

  def self.find_addresses str
    begin
      Mail::AddressList.new("#{str}".to_ascii.gsub(/<(<(.)*@(.)*>)(.)*>/, '\1'))
    rescue
      begin
        Mail::AddressList.new("#{str}".to_ascii.gsub(/<(<(.)*@(.)*>)(.)*>/, '\1').scan(/<(.*)>/).flatten.first)
      rescue
        Mail::AddressList.new("")
      end
    end
  end

  def self.strip_contact_name contact
    email_parts = contact.split(" ")
    email_parts.pop
    email_parts.join(" ")
  end

  def self.format_dates start_date_str, end_date_str
    return "" unless start_date_str && end_date_str
    start_time = DateTime.parse start_date_str
    end_time = DateTime.parse end_date_str

    if start_time.to_date == end_time.to_date
      start_time.strftime('%A %d %B %Y') + "<br>" + start_time.strftime('%H:%M') + " - " + end_time.strftime('%H:%M')
    else
      start_time.strftime('%A %d %B %Y, %H:%M') + "<br>" + end_time.strftime('%A %d %B %Y, %H:%M')
    end
  end

  def self.messages_and_delay_stats date, exclude_waiting_accounts_emails=false
    start_date = date.utc.beginning_of_month
    end_date = start_date + 1.month

    all_messages = Message
                       .where(from_me: true)
                       .where("received_at >= ? AND received_at < ?", start_date, end_date)

    messages = all_messages
                   .where.not(request_at: nil)

    incoming_messages = Message
                            .where(from_me: false)
                            .where("received_at >= ? AND received_at < ?", start_date, end_date)

    if exclude_waiting_accounts_emails
      accounts = Account.accounts_cache(mode: "light")
      account_emails_to_exclude = accounts.select{|k, v| v["company_hash"] && v["company_hash"]["working_hours"].values.uniq != [{"0" => ["0", "2400"]}]}.keys
      all_messages_thread_ids = messages.select(:messages_thread_id).map(&:messages_thread_id)
      messages_thread_ids_to_exclude = MessagesThread.where(account_email: account_emails_to_exclude, id: all_messages_thread_ids).select(:id).map(&:id)
      messages = messages.where.not(messages_thread_id: messages_thread_ids_to_exclude)
    end
    delays = messages
                 .select("EXTRACT(EPOCH FROM (received_at - request_at)) AS delay")
                 .map{|m| m['delay'] / 60.0}

    operator_hours_count = OperatorPresence.where("date >= ? AND date < ?", start_date, [end_date, DateTime.now].min).count / 2.0
    active_clients_count = MessagesThread.where("created_at >= ? AND created_at < ?", start_date, end_date).select(:account_email).distinct.count

    incoming_messages_count = incoming_messages.select(:server_message_id).distinct.count
    real_threads_count = messages.select(:messages_thread_id).distinct.count
    {
        "Messages and threads": {
            "Incoming messages": incoming_messages_count,
            "Outgoing messages": messages.count,
            "Threads with outgoing messages": real_threads_count,
            "Incoming messages per outgoing thread": (incoming_messages_count * 1.0 / real_threads_count).round(2),
            "Active clients": active_clients_count,
            "Outgoing threads per client": (real_threads_count * 1.0 / active_clients_count).round(2)
        },
        "Delays": {
            "Average delay": "#{(delays.inject{ |sum, el| sum + el } / delays.length).round(2)}'",
            "Delays - p10": "#{self.percentile(delays, 0.10).round(2)}'",
            "Delays - p25": "#{self.percentile(delays, 0.25).round(2)}'",
            "Delays - median": "#{self.percentile(delays, 0.5).round(2)}'",
            "Delays - p75": "#{self.percentile(delays, 0.75).round(2)}'",
            "Delays - p90": "#{self.percentile(delays, 0.9).round(2)}'"
        },
        "Performance": {
            "Operator hours": operator_hours_count,
            "Messages per operator hour": (incoming_messages_count / operator_hours_count).round(2),
            "Operator time per incoming message": "#{(operator_hours_count / incoming_messages_count * 60.0).round(2)}'",
            "Operator time per outgoing thread": "#{(operator_hours_count / real_threads_count * 60.0).round(2)}'",
            "Cost per client": "#{(operator_hours_count / active_clients_count * 4.6).round(2)}€"
        },
        "Other": {
          "Operator time < 30' spent by thread": "#{(OperatorActionsGroup.where(operator_id: Operator.where.not(privilege: Operator::PRIVILEGE_ADMIN).select(:id).map(&:id)).where("initiated_at > ? AND initiated_at < ?", start_date, end_date).where("duration < ?", 30 * 60.0).average(:duration) / 60.0).round(2)}'",
          "Missing request_at count": all_messages.count - messages.count,
        }
    }
  end

  def self.percentile(values, percentile)
    return nil if values.length == 0
    return values[0] if values.length == 1

    values_sorted = values.sort
    k = (percentile*(values_sorted.length-1)+1).floor - 1
    f = (percentile*(values_sorted.length-1)+1).modulo(1)

    values_sorted[k] + (f * (values_sorted[k+1] - values_sorted[k]))
  end

  def display_duration duration_in_seconds
    duration_in_seconds = duration_in_seconds.to_i
    hours = (duration_in_seconds/60)/60
    minutes = (duration_in_seconds/60)%60
    seconds = duration_in_seconds%60

    "#{(hours > 0)?"#{hours}h ":nil}#{minutes}' #{(seconds < 10)?"0#{seconds}":seconds}''"
  end

  def check_highlighting_in_recipients(string)
    sanitized_email = sanitize_email_address(string).downcase

    if @client_emails.include?(sanitized_email)
      #we gsub the < for its html unicode equivalent to prevent it from beeing interpreted as a balise
      "<span class='highlighted'>#{CGI::escapeHTML(string)}</span>"
    elsif @julie_emails.include?(sanitized_email)
      "<span class='julie-highlighted'>#{CGI::escapeHTML(string)}</span>"
    else
      CGI::escapeHTML(string)
    end

  end

  def sanitize_email_address(string)
    tmp = string.dup

    if tmp.include?('<')
      # Removing trailing > with the -2
      tmp = tmp[(tmp.index('<') + 1)..-2]
    end

    tmp.gsub!('>', '')

    tmp
  end
end
