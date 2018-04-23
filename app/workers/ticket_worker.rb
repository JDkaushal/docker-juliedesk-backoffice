class TicketWorker

  @queue = :jira_tickets

  def self.enqueue(data)
    Resque.enqueue(self, data)
  end

  def self.perform (data)
    data        = data.with_indifferent_access
    summary     = data.delete(:summary)
    description = data.delete(:description)

    TicketService.create_ticket(summary, description, data)
  end
end