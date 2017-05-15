require "rails_helper"

describe AccountFlows::ClientUnsubscribed do
  let(:client_email) { 'toto@email.com' }
  let!(:messages_threads) { FactoryGirl.create_list(:messages_thread_with_messages, 10, account_email: client_email) }
  let(:client_unsubscribed_flow) { AccountFlows::ClientUnsubscribed.new(client_email) }
  let!(:julie_alias) { create(:julie_alias, { email: 'julie@juliedesk.com', signature_en: 'toto', signature_fr: 'tata', footer_en: 'tete', footer_fr: 'frfr'}) }

  describe 'flow' do
    before :example do
      allow(Account).to receive(:accounts_cache).with(mode: 'light').and_return({ 'toto@email.com' => { 'subscribed' => false } })
    end

    context 'Some threads have an auto follow up reminder date set' do
      before(:example) do
        messages_threads[3].update(follow_up_reminder_date: Time.now)
        messages_threads[5].update(follow_up_reminder_date: Time.now)
        messages_threads[8].update(follow_up_reminder_date: Time.now)
      end

      it 'should reset the follow up reminder date on every threads that needs it' do
        client_unsubscribed_flow.trigger

        messages_threads[3].reload
        messages_threads[5].reload
        messages_threads[8].reload

        expect(messages_threads[3].follow_up_reminder_date).to be(nil)
        expect(messages_threads[5].follow_up_reminder_date).to be(nil)
        expect(messages_threads[8].follow_up_reminder_date).to be(nil)
      end
    end

    context 'Some threads are in a scheduling state' do
      let(:reply_all_recipients) { "{\"from\":[{\"email\":\"titi@email.com\",\"name\":\"Titi\"}],\"to\":[{\"email\":\"titi@email.com\",\"name\":\"Titi\"},{\"email\":\"julie.doce@ups.com\",\"name\":\"Julie Doce\"}],\"cc\":[{\"email\":\"martin.libre@gloe.com\",\"name\":\"Martin libre\"}]}" }

      before(:example) do
        messages_threads[3].update(status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT)
        messages_threads[5].update(status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CLIENT)
        messages_threads[8].update(status: MessageClassification::THREAD_STATUS_SCHEDULING_WAITING_FOR_CONTACT)

        account1 = Account.new
        account1.email = 'titi@email.com'
        account1.email_aliases = []

        messages_threads[3].messages.last.update(reply_all_recipients: reply_all_recipients)
        messages_threads[5].messages.last.update(reply_all_recipients: reply_all_recipients)
        messages_threads[8].messages.last.update(reply_all_recipients: reply_all_recipients)

        allow_any_instance_of(MessagesThread).to receive(:account).and_return(account1)
        allow_any_instance_of(MessagesThread).to receive(:julie_alias).and_return(julie_alias)
        allow(EmailServer).to receive(:deliver_message).and_return({'id' => 1})
        allow(EmailServer).to receive(:get_messages_thread).and_return({})
      end

      it 'should retrieve the correct threads from the BD' do
        expect(client_unsubscribed_flow.send(:get_account_scheduling_threads).map(&:id)).to eq([messages_threads[3].id, messages_threads[5].id, messages_threads[8].id])
      end

      it 'should send an automatic email to the necessary threads' do
        allow(client_unsubscribed_flow).to receive(:get_account_scheduling_threads).and_return([messages_threads[3], messages_threads[5], messages_threads[8]])
        last_message_thread3_message = messages_threads[3].messages.sort_by{|m| m.received_at}.last
        last_message_thread5_message = messages_threads[5].messages.sort_by{|m| m.received_at}.last
        last_message_thread8_message = messages_threads[8].messages.sort_by{|m| m.received_at}.last

        allow(messages_threads[3]).to receive(:get_last_message).and_return(last_message_thread3_message)
        allow(messages_threads[5]).to receive(:get_last_message).and_return(last_message_thread5_message)
        allow(messages_threads[8]).to receive(:get_last_message).and_return(last_message_thread8_message)

        expect(AutoReplyAccountNoticeWorker).to receive(:enqueue).with(last_message_thread3_message.id, 'account_gone_unsubscribe.client', 'titi@email.com')
        expect(AutoReplyAccountNoticeWorker).to receive(:enqueue).with(last_message_thread5_message.id, 'account_gone_unsubscribe.client', 'titi@email.com')
        expect(AutoReplyAccountNoticeWorker).to receive(:enqueue).with(last_message_thread8_message.id, 'account_gone_unsubscribe.client', 'titi@email.com')
        expect(EmailServer).to receive(:archive_thread).exactly(3).times

        client_unsubscribed_flow.trigger
      end
    end
  end
end