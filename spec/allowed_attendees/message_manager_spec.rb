require "rails_helper"

describe AllowedAttendees::MessageManager do

  describe 'extract_allowed_attendees' do
    let(:julie_aliases_emails) { ['juliealias1@email.com', 'juliealias2@email.com'] }
    let(:message) { FactoryGirl.create(:message_complete) }

    let(:text) { 'Corps du message avec fred@email.com et jean@dumat.com' }
    let(:html) { '<div>Corps du message avec fred@email.com et jean@dumat.com ainsi que gérard@gmail.com</div>' }
    let(:server_message) {
      {
          'id' => 1,
          'text' => text,
          'parsed_html' => html,
          'from' => 'Test Guy <fromEmail@email.com>',
          'to' => 'Julie Desk <julie@juliedesk.com>, Mpm Herve <rimot@mlk.com>',
          'cc' => 'Lol l <lol@lol.com>, defz l <kjuh@ssm.com>',
          'attachments_data' =>
              [
                  {
                      'filename' => 'invite.ics',
                      'name' => 'invite.ics',
                      'type' => 'application/ics',
                      'attachment_id' => 'ggtl-frefe-fferf',
                      'content_id' =>'',
                      'data_is_blocked' =>false
                  }
              ]
      }
    }

    subject { message.compute_allowed_attendees(julie_aliases_emails) }

    before(:example) do
      message.message_classifications.first.update(constraints: 'Contraints text freferferferfeferfer ferferferf constraintEmail@email.com et constraint2@email.com')
      message.server_message = server_message

      expect_any_instance_of(EmailServerInterface).to receive(:build_request).with(:fetch_ics, {:message_id=>1, :attachment_id=>"ggtl-frefe-fferf"}).and_return({'data' => "BEGIN:VCALENDAR\r\nPRODID:-//Google Inc//Google Calendar 70.9054//EN\r\nVERSION:2.0\r\nCALSCALE:GREGORIAN\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nDTSTART:20170418T140000Z\r\nDTEND:20170418T150000Z\r\nDTSTAMP:20170418T134956Z\r\nORGANIZER:mailto:frederic.grais@gmail.com\r\nUID:0qf680auedq4vfifbhqe40d9q4@google.com\r\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=\r\n TRUE;CN=frederic@juliedesk.com;X-NUM-GUESTS=0:mailto:frederic@juliedesk.com\r\nATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;RSVP=TRUE\r\n ;X-NUM-GUESTS=0:mailto:frederic.grais@gmail.com\r\nCREATED:20170418T134956Z\r\nDESCRIPTION:View your event at https://www.google.com/calendar/event?action\r\n =VIEW&eid=MHFmNjgwYXVlZHE0dmZpZmJocWU0MGQ5cTQgZnJlZGVyaWNAanVsaWVkZXNrLmNvb\r\n Q&tok=MjQjZnJlZGVyaWMuZ3JhaXNAZ21haWwuY29tNGQxNjE3M2M3NGNmOTlmMDRkYThkN2NlY\r\n mY0YjFiOTEzM2IzODU0YQ&ctz=Europe/Paris&hl=en.\r\nLAST-MODIFIED:20170418T134956Z\r\nLOCATION:\r\nSEQUENCE:0\r\nSTATUS:CONFIRMED\r\nSUMMARY:Test invit\r\nTRANSP:OPAQUE\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n"})
    end

    it 'should compute the correct allowed attendees for the message' do
      is_expected.to eq(["fred@email.com", "jean@dumat.com", "constraintEmail@email.com", "constraint2@email.com", "gerard@gmail.com", "fromemail@email.com", "julie@juliedesk.com", "rimot@mlk.com", "lol@lol.com", "kjuh@ssm.com", "frederic@juliedesk.com", "frederic.grais@gmail.com"])
    end


    context 'when emails are in span tags' do
      let(:text) { 'Bobbybobby@juliedesk.com and Johnnyjohnny@juliedesk.com' }
      let(:html) { '<span>Bobby</span><span>bobby@juliedesk.com</span> and <span>Johnny</span><span>johnny@juliedesk.com</span>' }

      it { is_expected.to include('bobby@juliedesk.com', 'johnny@juliedesk.com') }
    end

  end
end