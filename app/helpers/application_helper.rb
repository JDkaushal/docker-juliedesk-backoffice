module ApplicationHelper

  include ActionView::Helpers::TextHelper
  include ERB::Util
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

  # This is a custom method to parse attendees
  # It allows to keep not-ascii characters like accents
  # Performance: 19991/20000 (tested on mails in database vs the other method)
  def self.parse_attendees_custom str
    # Convert to string
    str = "#{str}"

    # Decode what's need to be decoded
    str = str.gsub(/\=\?utf\-8\?B\?([^\?]*)\?\=/) do |d|
      Base64.decode64(Regexp.last_match[1]).force_encoding('utf-8')
    end

    # Remove parenthesis
    str = str.gsub(/\([^\)]*\)/, "")
    str.gsub!('"', '')

    letter_regexp = /(?:(\p{L}))/ # international letters (includes chines, cyrillic,...)

    inside_email_regexp = /(?:#{letter_regexp}|\#)(?:#{letter_regexp}|\.|\-|\+|\_)*@(?:#{letter_regexp}|\-|\.)*(?:\.[a-zA-Z]*){1,2}/
    inside_name_regexp = /(?:#{letter_regexp}|\#|\s)(?:#{letter_regexp}|\-|\s|\u00A0|\\|"|\'|\’|\_|\>|\+|\.|:|[0-9]|\&|\@|\?|\/)*/
    email_regexp = /(?<email>#{inside_email_regexp})/
    name_regexp = /(?<name>#{inside_name_regexp})(?:\ \(.*\))?/

    possible_formats = [
        /#{name_regexp} <#{email_regexp}>/,
        /(?<name>\'#{inside_name_regexp}\')(?:\ \(.*\))? +<#{email_regexp}>/,
        /(?<name>#{inside_email_regexp}) +<#{email_regexp}>/,
        /(?<name>\'#{inside_email_regexp}\') +<#{email_regexp}>/,
        /#{name_regexp} <<#{email_regexp}>(?:[a-zA-Z]|\@)*>/,
        /<#{email_regexp}>/,
        /#{email_regexp}/
    ]

    re = /(?:\, ?|^)(?:#{possible_formats.join("|")})(?=>|$|\,)/


    str.to_enum(:scan, re).map do
      md = Regexp.last_match
      {name: nil, email: nil}.merge Hash[md.names.map{|n| [n.to_sym, md[n]]}]
    end
  end


  def self.find_addresses str
    # Necessary because Mail::AddressList.new decompose "Simon, Matthieu <Matthieu.Simon@rolandberger.com>" into two mails "Simon" and "Matthieu <Matthieu.Simon@rolandberger.com>"
    # So we need to remove non email string from the field for example
    # "Josephine, Vincent <Vincent.Josephine@rolandberger.com>, julie_desk <julie.desk@rolandberger.com>" becomes "Vincent <Vincent.Josephine@rolandberger.com>, julie_desk <julie.desk@rolandberger.com>"
    if str.present?
      # Remove '[' and ']'
      str.gsub!('"','')
      str.gsub!(/[\[|\]]/, '')
      str.gsub!(/\\/, '')
      str = str.split(',').reject{|s| !s.include?('@')}.join(',')
      str.strip!
    end

    res = begin
      Mail::AddressList.new("#{str}".to_ascii.gsub(/<(<(.)*@(.)*>)(.)*>/, '\1'))
    rescue
      begin
        Mail::AddressList.new("#{str}".to_ascii.gsub(/<(<(.)*@(.)*>)(.)*>/, '\1').scan(/<(.*)>/).flatten.first)
      rescue
        Mail::AddressList.new("")
      end
    end

    res_custom = begin
      data_items = self.parse_attendees_custom(str)
      al = OpenStruct.new({addresses: data_items.map do |data_item|
        add = Mail::Address.new
        add.address = data_item[:email]
        add.display_name = data_item[:name] if data_item[:name]
        add
      end})
      al
    rescue Exception => e
      p e
      nil
    end

    if res_custom.present?
      res_custom
    else
      res
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

    team_operator_ids = Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1,Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2,Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_3]).select(:id).map(&:id)


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
          "Operator time < 30' spent by thread": "#{(OperatorActionsGroup.where(operator_id: Operator.where(privilege: [Operator::PRIVILEGE_OPERATOR, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_1, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2, Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_3]).select(:id).map(&:id)).where("initiated_at > ? AND initiated_at < ?", start_date, end_date).where("duration < ?", 30 * 60.0).average(:duration) / 60.0).round(2)}'",
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

  def process_recipients_html(string)
    # sanitized_email = sanitize_email_address(string).downcase
    # qualifying_div_classes = []
    #
    # @computed_present_attendee_emails ||= @messages_thread.computed_data[:attendees].select{|att| att['isPresent'] == 'true'}.map{|att| att['email']}
    #
    # result = if @client_emails.include?(sanitized_email)
    #   #we gsub the < for its html unicode equivalent to prevent it from beeing interpreted as a balise
    #   "<span class='highlighted'>#{CGI::escapeHTML(string)}</span>"
    # elsif @computed_present_attendee_emails.include?(sanitized_email)
    #   "<span class='attendee-highlighted'>#{CGI::escapeHTML(string)}</span>"
    # elsif @julie_emails.include?(sanitized_email)
    #   "<span class='julie-highlighted'>#{CGI::escapeHTML(string)}</span>"
    # else
    #   CGI::escapeHTML(string)
    # end
    #
    # linked_attendees = (@messages_thread.computed_data[:linked_attendees] || {}).values.flatten
    # trusted_attendees = @messages_thread.computed_data[:trusted_attendees] || {}
    #
    # if linked_attendees.include?(sanitized_email)
    #   qualifying_div_classes.push(:linked_attendee)
    #   result += "<span class='linked-attendee-sprite' title='Récipiendaire lié'></span>"
    # end
    #
    # if trusted_attendees.present?
    #
    #
    # end
    #
    # global_classes = qualifying_div_classes.present? ? "class='#{qualifying_div_classes.join(' ')}'" : ''
    #
    # "<span #{global_classes}>#{result}</span>"

    EmailRecipients::Tagger.new(@messages_thread, @client_emails, @julie_emails, string).tag
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

  def text_to_html text
    text.split("\n").map{|line| "<div>#{(line.present?)?h(line):"<br>"}</div>"}.join("\n").html_safe
  end

  def pp arg
    if arg.class == String
      arg = JSON.parse(arg)
    end

    puts(JSON.pretty_generate(arg))
  end

  def self.extract_domain(email)
    if email.present? && email.include?('@')
      email.split('@')[-1].split('.')[0]
    end
  end

  def self.email_in_domain?(domains, email)
    domains.include?(email.split('@')[-1])
  end
end
