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

  def self.messages_and_delay_stats date
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


    delays = messages
                 .select("EXTRACT(EPOCH FROM (received_at - request_at)) AS delay")
                 .map{|m| m['delay'] / 60.0}

    {
        "Missing request_at count": all_messages.count - messages.count,
        "Incoming messages count": incoming_messages.select(:server_message_id).distinct.count,
        "Outgoing messages count": messages.count,
        "Threads with outgoing messages count": messages.select(:messages_thread_id).distinct.count,
        "Average delay": delays.inject{ |sum, el| sum + el } / delays.length,
        "Delays - p10": self.percentile(delays, 0.10),
        "Delays - p25": self.percentile(delays, 0.25),
        "Delays - median": self.percentile(delays, 0.5),
        "Delays - p75": self.percentile(delays, 0.75),
        "Delays - p90": self.percentile(delays, 0.9),
    }
  end

  def self.percentile(values, percentile)
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
    sanitized_email = sanitize_email_address(string)

    if @client_emails.include?(sanitized_email)
      #we gsub the < for its html unicode equivalent to prevent it from beeing interpreted as a balise
      "<span class='highlighted'>#{string.gsub('<', '&#60;')}</span>"
    elsif @julie_emails.include?(sanitized_email)
      "<span class='julie-highlighted'>#{string.gsub('<', '&#60;')}</span>"
    else
      sanitized_email
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
