require "rails_helper"

describe PostponeEvents::CalendarServerEventFinder do

  describe 'find' do
    let(:event_data) { {start_date: '2017-03-22T15:00:00+01:00', summary: 'Test Event'} }
    subject(:finder) { PostponeEvents::CalendarServerEventFinder.new(event_data) }

    it 'should call the calendar server' do
      expect_any_instance_of(CalendarServerInterface).to receive(:build_request).with(:get_owner_event, event_data)
      subject.find
    end

  end

end