def import_email_server_thread(server_thread_id)

  server_thread = EmailServer.get_messages_thread(server_thread_id: server_thread_id)


  accounts_cache = Account.accounts_cache(mode: "light")
  account_email = MessagesThread.find_account_email(server_thread, {accounts_cache: accounts_cache})
  if account_email
    account = Account.create_from_email(account_email, {accounts_cache: accounts_cache})
  else
    account = nil
  end

  messages_thread = MessagesThread.new(
      server_thread_id: server_thread['id'],
      in_inbox: true,
      server_version: server_thread['version'],
      subject: server_thread['subject'],
      snippet: server_thread['snippet'],
      messages_count: server_thread['messages'].length,
      account_email: account.try(:email),
      account_name: account.try(:usage_name),
  )

  server_thread['messages'].each do |server_message|
    messages_thread.messages << Message.new(
        server_message_id: server_message['id'],
        received_at: DateTime.parse(server_message['date']),
        reply_all_recipients: Message.generate_reply_all_recipients(server_message).to_json,
        from_me: server_message['from_me']
    )
  end

  messages_thread.save
end

#import_email_server_thread 505237