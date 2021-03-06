class ClientRequest < ActiveRecord::Base
  belongs_to :messages_thread

  def self.compute_count(user_ids=nil, team_identifiers=nil, options={}, from_date, to_date)
    client_requests = ClientRequest.where('date > ? AND date < ?', from_date, to_date)
    if user_ids.present?
      raise 'Cannot provide both user_ids and team_identifiers params' if team_identifiers.present?
      client_requests = client_requests.where(user_id: user_ids)
    elsif team_identifiers.present?
      client_requests = client_requests.where(team_identifier: team_identifiers)
    else
      raise 'Please provide user_ids or team_identifiers param'
    end
    if options[:detailed]
      {
          count: client_requests.count,
          message_thread_ids: client_requests.select(:messages_thread_id).map(&:messages_thread_id)
      }
    else
      client_requests.count
    end
  end

  def self.create_if_needed(messages_thread)
    not_request_statuses = [
        nil,
        MessageClassification::THREAD_STATUS_OTHER,
        MessageClassification::THREAD_STATUS_DOES_NOT_CONCERN_CLIENT,
        MessageClassification::THREAD_STATUS_HANDLED_IN_OTHER_THREADS,
        MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT
    ]

    return false if not_request_statuses.include? messages_thread.status
    return false unless messages_thread.account

    if ClientRequest.find_by_messages_thread_id(messages_thread.id)
      false
    else
      ClientRequest.create(
          messages_thread_id: messages_thread.id,
          date: messages_thread.created_at,
          user_id: messages_thread.account.user_id,
          team_identifier: messages_thread.account.company_hash.try(:[], 'identifier')
      )
      true
    end

  end

end