require "rails_helper"

describe FollowUp::CheckRoutineJob do

  describe 'perform' do

    it 'should update the correct messages threads' do
      mt1 = FactoryGirl.create(:messages_thread, should_follow_up: false, follow_up_reminder_date: nil)
      mt2 = FactoryGirl.create(:messages_thread, should_follow_up: false, follow_up_reminder_date: Time.now - 4.hour)
      mt3 = FactoryGirl.create(:messages_thread, should_follow_up: false, follow_up_reminder_date: Time.now - 1.hour)
      mt4 = FactoryGirl.create(:messages_thread, should_follow_up: false, follow_up_reminder_date: nil)


      expect(mt1.should_follow_up).to be(false)
      expect(mt2.should_follow_up).to be(false)
      expect(mt3.should_follow_up).to be(false)
      expect(mt4.should_follow_up).to be(false)

      FollowUp::CheckRoutineJob.new.perform

      mt2.reload
      mt3.reload

      expect(mt2.should_follow_up).to be(true)
      expect(mt3.should_follow_up).to be(true)
    end

  end

end