class JulieActionMigrationCalendarServer

  @queue = :julie_action_migration_calendar_server
  def self.enqueue(date, specific_ids = [])
    Resque.enqueue(self, date, specific_ids)
  end

  def self.perform (date, specific_ids)
    JulieAction.reassociate_events_to_calendar_server_if_possible(date, specific_ids)
  end
end