class ClientSuccessTrackingHelpers
  require 'mixpanel-ruby'

  def self.async_track(event_name, account_email, properties={})
    ClientSuccessTrackingWorker.enqueue(event_name, account_email, properties.merge({time: Time.now.to_i}))
  end

  def self.async_track_new_request_sent(messages_thread_id)
    ClientSuccessTrackingWithComputeWorker.enqueue(:track_new_request_sent, messages_thread_id)
  end

  def self.track_new_request_sent(messages_thread_id)
    messages_thread = MessagesThread.find messages_thread_id
    server_thread = messages_thread.server_thread
    julie_aliases = JulieAlias.all
    julie_aliases_emails = julie_aliases.map(&:email)

    # Compute attendees count
    thread_recipients = Set.new
    server_thread['messages'].each do |server_message|
      message_recipients = Message.generate_reply_all_recipients(server_message, julie_aliases_emails)
      thread_recipients.merge((message_recipients[:from] + message_recipients[:to] + message_recipients[:cc]).map{|recipient| recipient[:email]})
    end
    attendees_count = thread_recipients.size

    # Compute internal attendees count
    secondary_clients = messages_thread.secondary_clients
    internal_attendees_count = secondary_clients.size + messages_thread.linked_attendees.values.flatten.size + 1 # Add 1 to include the thread owner (main client)

    # Compute external attendees count
    external_attendees_count = attendees_count - internal_attendees_count

    # Track
    ClientSuccessTrackingHelpers.track('New Request Sent', messages_thread.account_email, {
        bo_thread_id: messages_thread.id,
        julie_alias: !(MessagesThread.julie_aliases_from_server_thread(server_thread, {julie_aliases: julie_aliases}).map(&:email).include? ENV['COMMON_JULIE_ALIAS_EMAIL']),
        'Number of Participants' => attendees_count,
        'Number of External Participants' => external_attendees_count,
        'Number of Internal Participants' => internal_attendees_count,
        'email_recipients' => thread_recipients.to_a.join(','),
        'email_title' => messages_thread.subject
    })
  end

  def self.track(event_name, account_email, properties)
    analytics = SEGMENT_CLIENT
    account_id = Account.accounts_cache(mode: 'light').find{|email, infos| email.downcase == "#{account_email}".downcase}.try('[]', 1).try('[]', 'id')
    account_id = account_id.to_s.prepend("#{ENV['SPECIFIC_TENANT']}-") if ENV['SPECIFIC_TENANT'].present?

    if account_id && analytics
      analytics.track(user_id: account_id, event: event_name, properties: properties)
    end

  end
end