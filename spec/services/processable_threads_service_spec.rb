require "rails_helper"

describe ProcessableThreadsService do

  describe '.run_verification!' do

    shared_examples 'jira ticket not created' do
      it {
        expect(TicketWorker).not_to receive(:enqueue)
        subject
      }
    end

    shared_examples 'jira ticket created' do
      it {
        expect(TicketWorker).to receive(:enqueue)
        subject
      }
    end

    shared_examples 'email notification not sent' do
      it {
        expect(AutoEmailWorker).not_to receive(:enqueue)
        subject
      }
    end

    shared_examples 'email notification sent' do
      it {
        expect(AutoEmailWorker).to receive(:enqueue)
        subject
      }
    end


    shared_context 'ticket does not exist' do
      before(:example) { allow(TicketService).to(receive(:ticket_exist?).and_return(false)) }
    end

    shared_context 'ticket already exists' do
      before(:example) { allow(TicketService).to(receive(:ticket_exist?).and_return(true)) }
    end


    let(:messages_thread_params) { {} }
    let(:messages_thread) { create(:messages_thread, { in_inbox: true, tags: [MessagesThread::SYNCING_TAG]}.merge(messages_thread_params)) }
    let!(:message)        { create(:message, messages_thread: messages_thread, from_me: false) }

    subject { ProcessableThreadsService.run_verification! }

    before(:each) do
      allow(ProcessableThreadsService).to receive(:threshold_date).and_return(15.minutes.ago)
      allow(TicketService).to receive(:create_ticket).and_return(false)
      allow(AutoEmailWorker).to receive(:enqueue).and_return(false)
    end

    context 'when thread is not syncing' do
      include_context 'ticket does not exist'
      let(:messages_thread_params) { { tags: [] } }

      it_behaves_like 'jira ticket not created'
      it_behaves_like 'email notification not sent'
    end

    context 'when thread is not in inbox' do
      include_context 'ticket does not exist'
      let(:messages_thread_params) { { in_inbox: false } }

      it_behaves_like 'jira ticket not created'
      it_behaves_like 'email notification not sent'
    end

    context 'when thread is syncing for less than 15 minutes' do
      include_context 'ticket does not exist'
      before(:example) { allow_any_instance_of(MessagesThread).to receive(:syncing_since).and_return(5.minutes.ago) }

      it_behaves_like 'jira ticket not created'
      it_behaves_like 'email notification not sent'
    end

    context 'when thread is syncing for more than 15 minutes' do
      include_context 'ticket does not exist'
      before(:example) { allow_any_instance_of(MessagesThread).to receive(:syncing_since).and_return(20.minutes.ago) }

      it_behaves_like 'jira ticket created'
      it_behaves_like 'email notification sent'
    end

    context 'when ticket concerning this thread already exist' do
      include_context 'ticket already exists'
      before(:example) { allow_any_instance_of(MessagesThread).to receive(:syncing_since).and_return(20.minutes.ago) }

      it_behaves_like 'jira ticket not created'
      it_behaves_like 'email notification sent'
    end

    context 'when thread is in admin' do
      include_context 'ticket does not exist'
      before(:example) { allow_any_instance_of(MessagesThread).to receive(:syncing_since).and_return(20.minutes.ago) }
      let(:messages_thread_params) { { sent_to_admin: true } }

      it_behaves_like 'jira ticket not created'
      it_behaves_like 'email notification not sent'
    end
  end

end