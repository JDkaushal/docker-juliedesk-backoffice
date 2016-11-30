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
    let(:now) { DateTime.new(2016, 01, 01) }
    before { allow(Time).to receive(:now).and_return(now) }
    subject {  julie_action.send(:get_suggested_dates_barycentre).try(:to_s) }

    context 'when no suggested dates' do
      let(:julie_action) { create(:julie_action, date_times: '[]') }

      it 'default barycentre is Now + 3 days' do
        is_expected.to eq("2016-01-04T00:00:00+00:00")
      end
    end

    context '1 date' do
      let(:julie_action) { create(:julie_action, date_times: "[{\"date\":\"2016-06-30T12:15:00+00:00\"}]") }

      it 'should return the correct date' do
        is_expected.to eq("2016-03-31T18:15:00+00:00")
      end
    end

    context 'multiple dates' do
      let(:date_times) { "[{\"date\":\"2016-06-30T12:15:00+00:00\"}, {\"date\":\"2016-07-04T14:15:00+00:00\"}, {\"date\":\"2016-07-10T19:55:00+00:00\"}]" }
      let(:julie_action) { create(:julie_action, date_times: date_times) }

      it 'should return the correct date' do
        is_expected.to eq("2016-04-03T20:15:00+00:00")
      end
    end

    context 'action nature is JulieAction::JD_ACTION_CHECK_AVAILABILITIES' do
      let(:julie_action) { create(:check_availabilities_action) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'action nature is JulieAction::JD_ACTION_CHECK_AVAILABILITIES with suggested date_times' do
      let(:date_times) { "[{\"date\":\"2016-06-30T12:15:00+00:00\"}, {\"date\":\"2016-07-04T14:15:00+00:00\"}, {\"date\":\"2016-07-10T19:55:00+00:00\"}]"}
      let(:julie_action) { create(:check_availabilities_action, date_times: date_times) }

      it 'returns barycentre of suggested dates' do
        is_expected.to eq("2016-04-03T20:15:00+00:00")
      end
    end

  end
end