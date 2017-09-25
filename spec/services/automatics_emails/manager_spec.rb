require "rails_helper"

describe AutomaticsEmails::Manager do

  describe 'send' do

    context 'TYPE_ACCESS_LOST_IN_THREAD' do

      let(:automatic_email_type) { AutomaticsEmails::Manager::TYPE_ACCESS_LOST_IN_THREAD }

      let(:account_email) { 'account@gmail.com' }
      let(:messages_thread_1) { FactoryGirl.create(:messages_thread, account_email: account_email) }
      let(:messages_thread_2) { FactoryGirl.create(:messages_thread, account_email: account_email) }

      let(:message) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id) }

      subject(:manager) { AutomaticsEmails::Manager.new(message) }

      context 'No auto automatics emails sent' do
        let!(:message1) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id) }
        let!(:message2) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id) }
        let!(:message3) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id) }
        let!(:message4) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id) }

        it 'should send the email' do
          expect(manager).to receive(:deliver)

          manager.send(automatic_email_type, {})
        end
      end

      context 'Less than 5 auto emails of the specified type sent in another thread in the last 4 hours' do
        let!(:message1) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id) }
        let!(:message2) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id) }
        let!(:message3) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }
        let!(:message4) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }
        let!(:message5) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }
        let!(:message6) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }
        let!(:message7) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id) }


        it 'should sent the email' do
          expect(manager).to receive(:deliver)

          manager.send(automatic_email_type, {})
        end
      end


      context 'Should not send the email' do
        context 'One auto email of the specified type was sent in the same thread in the last 4 hours' do
          let!(:message1) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id, auto_email_kind: automatic_email_type) }
          let!(:message2) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id) }
          let!(:message3) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id) }
          let!(:message4) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id) }

          it 'should not send the email' do
            expect(manager).not_to receive(:deliver)

            manager.send(automatic_email_type, {})
          end
        end
        
        context "More than 4 auto emails of the specified type where sent for the user in the last 4 hours" do
          let!(:message1) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id) }
          let!(:message2) { FactoryGirl.create(:message, messages_thread_id: messages_thread_1.id) }
          let!(:message3) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }
          let!(:message4) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }
          let!(:message5) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }
          let!(:message6) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }
          let!(:message7) { FactoryGirl.create(:message, messages_thread_id: messages_thread_2.id, auto_email_kind: automatic_email_type) }

          it 'should not send the email' do
            expect(manager).not_to receive(:deliver)

            manager.send(automatic_email_type, {})
          end
        end


      end
    end
  end
end