module ApplicationHelper


  def self.hash_from_parenthesized_contact contact
    {
        email: contact.split(" ").last.gsub("(", "").gsub(")", ""),
        name: self.strip_contact_name(contact)
    }
  end

  def self.strip_email contact
    # Seems like an email contained in a string like "gtrgrt, hyth <frf.ff@ff.com>" will not be found
    # Instead it will return "gtrgrt", removing the comma fixes it
    begin
      Mail::Address.new(contact.to_ascii.gsub(',', '')).address
      #ApplicationHelper.find_addresses(contact).addresses.first.address
    rescue
      nil
    end
  end

  def self.find_addresses str
    # Necessary because Mail::AddressList.new decompose "Simon, Matthieu <Matthieu.Simon@rolandberger.com>" into two mails "Simon" and "Matthieu <Matthieu.Simon@rolandberger.com>"
    # So we need to remove non email string from the fieald for example
    # "Josephine, Vincent <Vincent.Josephine@rolandberger.com>, julie_desk <julie.desk@rolandberger.com>" becomes "Vincent <Vincent.Josephine@rolandberger.com>, julie_desk <julie.desk@rolandberger.com>"
    if str.present?
      str = str.split(',').reject{|s| !s.include?('@')}.join(',')

    end

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

    team_operator_ids = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1,Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2]).select(:id).map(&:id)


    flagged_server_messages_ids = EmailServer.search_messages({
                                                                  after: start_date.to_s,
                                                                  before: end_date.to_s,
                                                                  labels: "flag",
                                                                  limit: 1000
                                                              })['messages']['ids']
    flagged_messages_thread_ids = Message.where(server_message_id: flagged_server_messages_ids).select(:messages_thread_id).distinct.map(&:messages_thread_id)

    reviewed_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where(operator_id: team_operator_ids, review_notation: [0, 1, 2, 3, 4, 5]).count
    errors_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where(operator_id: team_operator_ids, review_notation: [0, 1, 2, 3]).count

    flagged_errors_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where(operator_id: team_operator_ids, review_notation: [0, 1, 2, 3], messages_thread_id: flagged_messages_thread_ids).count
    non_flagged_errors_count = errors_count - flagged_errors_count

    flagged_reviewed_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where(operator_id: team_operator_ids, review_notation: [0, 1, 2, 3, 4, 5], messages_thread_id: flagged_messages_thread_ids).count
    non_flagged_reviewed_count = reviewed_count - flagged_reviewed_count

    actions_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where(operator_id: team_operator_ids).count
    flagged_actions_count = OperatorActionsGroup.where("initiated_at >= ? AND initiated_at < ?", start_date, [end_date, DateTime.now].min).where(operator_id: team_operator_ids, messages_thread_id: flagged_messages_thread_ids).count
    non_flagged_actions_count = actions_count - flagged_actions_count

    errors_rate = (
    (flagged_errors_count * flagged_actions_count * 1.0 / flagged_reviewed_count) +
    (non_flagged_errors_count * non_flagged_actions_count * 1.0 / non_flagged_reviewed_count)
    ) / actions_count

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
        "Quality": {
            "Error rate": "#{(errors_rate * 100.0).round(2)}%"
        },
        "Other": {
          "Operator time < 30' spent by thread": "#{(OperatorActionsGroup.where(operator_id: Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2]).select(:id).map(&:id)).where("initiated_at > ? AND initiated_at < ?", start_date, end_date).where("duration < ?", 30 * 60.0).average(:duration) / 60.0).round(2)}'",
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

    @computed_present_attendee_emails ||= @messages_thread.computed_data[:attendees].select{|att| att['isPresent'] == 'true'}.map{|att| att['email']}

    if @client_emails.include?(sanitized_email)
      #we gsub the < for its html unicode equivalent to prevent it from beeing interpreted as a balise
      "<span class='highlighted'>#{CGI::escapeHTML(string)}</span>"
    elsif @computed_present_attendee_emails.include?(sanitized_email)
      "<span class='attendee-highlighted'>#{CGI::escapeHTML(string)}</span>"
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

  def display_review_sorting_link(attribute, params, &block)
    direction = :not_sorting
    if params[:sort] && params[:sort][:direction] && params[:sort][:attribute]
      direction_params = params[:sort][:direction].to_sym
      attribute_params = params[:sort][:attribute].to_sym

      if attribute == attribute_params
        direction = direction_params == :asc ? :desc : :asc
      end
    end

    link_to review_root_path(sort: {attribute: attribute, direction: direction}) do
      glyphicon_class = if direction == :not_sorting
        'glyphicon-resize-vertical'
      else
        direction == :asc ? 'glyphicon-chevron-down' : 'glyphicon-chevron-up'
      end

      block.call(glyphicon_class)
    end
  end
end
