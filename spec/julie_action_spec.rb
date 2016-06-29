require "rails_helper"

describe JulieAction do

  describe 'get_messages_thread_reminder_date' do

    context 'action nature is JulieAction::JD_ACTION_SUGGEST_DATES' do
      before(:each) do
        @ja = FactoryGirl.create(:julie_action, action_nature: JulieAction::JD_ACTION_SUGGEST_DATES)
      end

      it 'should call the correct method' do
        expect_any_instance_of(JulieAction).to receive(:get_suggested_dates_barycentre)
        @ja.get_messages_thread_reminder_date
      end
    end

    context 'action nature is JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS' do
      before(:each) do
        @ja = FactoryGirl.create(:julie_action, action_nature: JulieAction::JD_ACTION_FOLLOW_UP_CONTACTS)
      end

      it 'should call the correct method' do
        expect_any_instance_of(JulieAction).to receive(:get_suggested_dates_barycentre)
        @ja.get_messages_thread_reminder_date
      end
    end

    context 'action nature is JulieAction::JD_ACTION_CHECK_AVAILABILITIES' do
      before(:each) do
        @ja = FactoryGirl.create(:julie_action, action_nature: JulieAction::JD_ACTION_CHECK_AVAILABILITIES)
      end

      it 'should call the correct method' do
        expect_any_instance_of(JulieAction).to receive(:get_suggested_dates_barycentre)
        @ja.get_messages_thread_reminder_date
      end
    end

    context 'action nature is JulieAction::JD_ACTION_WAIT_FOR_CONTACT' do
      before(:each) do
        @ja = FactoryGirl.create(:julie_action, action_nature: JulieAction::JD_ACTION_WAIT_FOR_CONTACT)
      end

      it 'should return the correct value' do
        now = DateTime.new(2016, 01, 01)
        allow(Time).to receive(:now).and_return(now)

        expect(@ja.get_messages_thread_reminder_date).to eq(now + 3.days)
      end
    end

    context 'action nature is JulieAction::JD_ACTION_FREE_ACTION' do
      before(:each) do
        @ja = FactoryGirl.create(:julie_action, action_nature: JulieAction::JD_ACTION_FREE_ACTION)
      end

      it 'should return the correct value' do
        now = DateTime.new(2016, 01, 01)
        allow(Time).to receive(:now).and_return(now)

        expect(@ja.get_messages_thread_reminder_date).to eq(now + 3.days)
      end
    end
  end

  describe 'get_suggested_dates_barycentre' do

    context 'no suggested dates' do
      before(:each) do
        @ja = FactoryGirl.create(:julie_action, date_times: '[]')

      end

      it 'should return nil' do
        expect(@ja.send(:get_suggested_dates_barycentre)).to be(nil)
      end
    end

    context '1 date' do
      before(:each) do
        allow(Time).to receive(:now).and_return(DateTime.new(2016, 01, 01))
        @ja = FactoryGirl.create(:julie_action, date_times: "[{\"date\":\"2016-06-30T12:15:00+00:00\"}]")
      end

      it 'should return nil' do
        expect(@ja.send(:get_suggested_dates_barycentre).to_s).to eq("2016-03-31T10:10:00+00:00")
      end
    end

    context 'multiple dates' do
      before(:each) do
        allow(Time).to receive(:now).and_return(DateTime.new(2016, 01, 01))
        @ja = FactoryGirl.create(:julie_action, date_times: "[{\"date\":\"2016-06-30T12:15:00+00:00\"}, {\"date\":\"2016-07-04T14:15:00+00:00\"}, {\"date\":\"2016-07-10T19:55:00+00:00\"}]")
      end

      it 'should return nil' do
        expect(@ja.send(:get_suggested_dates_barycentre).to_s).to eq("2016-04-03T10:10:00+00:00")
      end
    end
  end
end