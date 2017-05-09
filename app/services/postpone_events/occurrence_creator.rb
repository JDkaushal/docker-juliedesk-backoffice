module PostponeEvents
  class OccurrenceCreator

    attr_reader :event_data

    def initialize(event_data)
      @event_data = event_data
    end

    def create
      create_on_calendar_server
    end

    private

    def create_on_calendar_server
      CalendarServerInterface.new.build_request(:create_occurrence, @event_data)
    end

  end
end