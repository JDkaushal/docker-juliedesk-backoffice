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
        'other',
        'does_not_concern_client',
        'handled_in_other_threads'
    ]

    return if not_request_statuses.include? messages_thread.status

    ClientRequest.find_or_create_by(messages_thread_id: messages_thread.id) do |client_request|
      client_request.date = messages_thread.created_at
      client_request.user_id = messages_thread.account.user_id
      client_request.team_identifier = messages_thread.account.company_hash.try(:[], 'identifier')
    end

  end

end