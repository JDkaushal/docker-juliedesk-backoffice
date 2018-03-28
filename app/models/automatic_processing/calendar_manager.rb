module AutomaticProcessing

  class MeetingRoomsManager
    attr_reader :julie_action

    def initialize(julie_action)
      @julie_action = julie_action
    end

    def create_event(params)


      response = EventsManagement::BaseInterface.new.build_request(:create, params)

      if response && response['status'] == 'success'
        self.update({
                        calendar_id: response['data']['calendar_id'],
                        calendar_login_username: account.email,
                        event_id: response['data']['id']
                    })
      else
        raise AutomaticProcessing::Exceptions::EventCreationError.new(self.id)
      end
    end
  end
end