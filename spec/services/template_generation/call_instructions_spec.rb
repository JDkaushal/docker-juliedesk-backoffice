require "rails_helper"

describe TemplateGeneration::CallInstructions do

  let(:attendees) { [] }
  let(:call_instructions) { { target: 'later', support: '', target_infos: { }, details: '' } }
  let(:message_classification_params) { { } }
  let(:message_classification) do
    create(:automated_message_classification, { appointment_nature: 'call', attendees: attendees.map(&:to_h).to_json, call_instructions: call_instructions.to_json }.merge(message_classification_params))
  end

  describe '.generate' do
    subject { TemplateGeneration::CallInstructions.generate(message_classification) }

    context 'when no attendees' do
      let(:attendees) { [] }
      it { is_expected.to eq('') }
    end

    context 'when target is client wich is only attendee' do
      let(:attendees) { [ Attendee.new(email: 'bob@juliedesk.com', first_name: 'Bob', last_name: 'Doe', is_thread_owner: true, is_client: true) ] }
      let(:call_instructions) { { target: 'client', support: 'mobile', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '0602030405' } }
      it { is_expected.to eq('') }
    end

    context 'when target is client and details not available' do
      let(:attendees) {
        [
            Attendee.new(email: 'bob@juliedesk.com', first_name: 'Bob', last_name: 'Doe', is_present: true, is_thread_owner: true, is_client: true),
            Attendee.new(first_name: 'John', last_name: 'Doe', is_present: true, is_thread_owner: false, is_client: false),
        ]
      }
      let(:call_instructions) { { target: 'client', support: 'mobile', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '' } }
      it { is_expected.to eq('') }
    end

    context 'when target is client for support confcall (details not available)' do
      let(:attendees) {
        [
            Attendee.new(email: 'bob@juliedesk.com', first_name: 'Bob', last_name: 'Doe', is_present: true, is_thread_owner: true, is_client: true),
            Attendee.new(first_name: 'John', last_name: 'Doe', is_present: true, is_thread_owner: false, is_client: false),
        ]
      }
      let(:call_instructions) { { target: 'client', support: 'confcall', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '' } }
      it { is_expected.to eq('') }
    end

    context 'when target is client for support confcall (details not available)' do
      let(:attendees) {
        [
            Attendee.new(email: 'bob@juliedesk.com', first_name: 'Bob', last_name: 'Doe', confcall_instructions: 'Appeler au +33102030405', is_present: true, is_thread_owner: true, is_client: true),
            Attendee.new(first_name: 'John', last_name: 'Doe', is_present: true, is_thread_owner: false, is_client: false),
        ]
      }
      let(:call_instructions) { { target: 'client', support: 'confcall', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: 'Appeler au +33102030405' } }
      it { is_expected.to eq('Appeler au +33102030405') }
    end


    context 'when target is client and details available' do
      let(:attendees) {
        [
            Attendee.new(email: 'bob@juliedesk.com' ,first_name: 'Bob', last_name: 'Doe', is_present: true, is_thread_owner: true, is_client: true),
            Attendee.new(first_name: 'John', last_name: 'Doe', is_present: true, is_thread_owner: false, is_client: false),
        ]
      }
      let(:call_instructions) { { target: 'client', support: 'mobile', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '0602030405' } }
      it { is_expected.to eq("John Doe appelle Bob Doe au 0602030405") }
    end

    context 'when target is client with multiple attendees' do
      let(:attendees) {
        [
            Attendee.new(email: 'bob@juliedesk.com', first_name: 'Bob', last_name: 'Doe', is_present: true, is_thread_owner: true, is_client: true),
            Attendee.new(first_name: 'John', last_name: 'Doe', is_present: true, is_thread_owner: false, is_client: false),
            Attendee.new(first_name: 'Robert', last_name: 'Doe', is_present: true, is_thread_owner: false, is_client: false),
        ]
      }
      let(:call_instructions) { { target: 'client', support: 'mobile', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '0602030405' } }

      it { is_expected.to eq("Appeler Bob Doe au 0602030405") }
    end



    context 'when target is interlocutor and details not available' do
      let(:attendees) {
        [
            Attendee.new(email: 'bob@juliedesk.com', first_name: 'Bob', last_name: 'Doe', is_present: true, is_thread_owner: true, is_client: true),
            Attendee.new(first_name: 'John', last_name: 'Doe', is_present: true, is_thread_owner: false, is_client: false),
        ]
      }
      let(:call_instructions) { { target: 'interlocutor', support: 'mobile', target_infos: { email: 'john@juliedesk.com', name: 'John Doe' }, details: '' } }

      it { is_expected.to eq('') }
    end

    context 'when target is interlocutor and details available' do
      let(:attendees) {
        [
            Attendee.new(email: 'bob@juliedesk.com', first_name: 'Bob', last_name: 'Doe', is_present: true, is_thread_owner: true, is_client: true),
            Attendee.new(first_name: 'John', last_name: 'Doe', is_present: true, is_thread_owner: false, is_client: false, landline: '0102030405'),
        ]
      }
      let(:call_instructions) { { target: 'interlocutor', support: 'mobile', target_infos: { email: 'john@juliedesk.com', name: 'John Doe' }, details: '0102030405' } }

      it { is_expected.to eq("Bob Doe appelle John Doe au 0102030405") }
    end

    context 'when target is later' do
      let(:call_instructions) { { target: 'later', support: '', target_infos: { }, details: '' } }
      it { is_expected.to eq('') }
    end

  end

end