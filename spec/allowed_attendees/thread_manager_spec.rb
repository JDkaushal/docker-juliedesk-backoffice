require "rails_helper"

describe AllowedAttendees::ThreadManager do

  describe 'compute_allowed_attendees' do
    let(:messages_thread) { FactoryGirl.create(:messages_thread_with_messages, messages_count: 3, clients_in_recipients: ['client1@email.com', 'client2@email.com', 'client3@email.com'], accounts_candidates: ['accountCandidate1@mail.com', 'accountCandidate2@mail.com'], account_email: 'client1@email.com') }

    before(:example) do
      messages_thread.messages[0].update(allowed_attendees: ['message1AllowedAttendee1@mail.com', 'message1AllowedAttendee2@mail.com'])
      messages_thread.messages[1].update(allowed_attendees: ['message2AllowedAttendee1@mail.com'])
      messages_thread.messages[2].update(allowed_attendees: ['message3AllowedAttendee1@mail.com', 'message3AllowedAttendee2@mail.com'])

      allow(Account).to receive(:accounts_cache_for_email).with('client1@email.com').and_return({
                                                                                                    'email' => 'client1@email.com',
                                                                                                    'email_aliases' => ['alias1@email.com', 'alias2@email.com'],
                                                                                                    'current_notes' => ''
                                                                                                })

      allow(Account).to receive(:accounts_cache_for_email).with('client2@email.com').and_return({
                                                                                                    'email' => 'client2@email.com',
                                                                                                    'email_aliases' => [],
                                                                                                    'current_notes' => 'ferifjeroifjeorijf frefref currentNotes1Client2@email.com currentNotes2Client2@email.com'
                                                                                                })

      allow(Account).to receive(:accounts_cache_for_email).with('client3@email.com').and_return({
                                                                                                    'email' => 'client3@email.com',
                                                                                                    'email_aliases' => [],
                                                                                                    'current_notes' => 'ferifjeroifjeorijf frefref currentNotes1Client3@email.com currentNotes2Client3@email.com'
                                                                                                })

      messages_thread.messages[2].message_classifications.create(classification: MessageClassification::ASK_DATE_SUGGESTIONS, attendees: [{'email' => 'fromComputedData1@email.com'}, {'email' => 'fromComputedData2@email.com'}].to_json)
    end

    it 'should compute the correct allowed attendees' do
      expect(messages_thread.compute_allowed_attendees).to eq([
                                                               "client1@email.com",
                                                               "alias1@email.com",
                                                               "alias2@email.com",
                                                               "currentNotes1Client2@email.com",
                                                               "currentNotes2Client2@email.com",
                                                               "currentNotes1Client3@email.com",
                                                               "currentNotes2Client3@email.com",
                                                               "accountCandidate1@mail.com",
                                                               "accountCandidate2@mail.com",
                                                               "message1AllowedAttendee1@mail.com",
                                                               "message1AllowedAttendee2@mail.com",
                                                               "message2AllowedAttendee1@mail.com",
                                                               "message3AllowedAttendee1@mail.com",
                                                               "message3AllowedAttendee2@mail.com",
                                                               "fromComputedData1@email.com",
                                                               "fromComputedData2@email.com"
                                                             ])
    end
  end
end