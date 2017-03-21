module PostponeEvents
  class CalendarServerEventFinder

    attr_reader :event_data

    def initialize(event_data)
      @event_data = event_data
    end

    def find
      search_on_calendar_server
    end

    private

    def search_on_calendar_server
      CalendarServerInterface.new.build_request(:get_owner_event, @event_data)
    end
  end
end