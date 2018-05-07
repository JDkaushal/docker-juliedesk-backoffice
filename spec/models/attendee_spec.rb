require "rails_helper"

describe Attendee do
  let(:attendee_params) { { } }
  let(:default_attendee_params) { { email: 'bob@juliedesk.com' } }
  let(:attendee) { Attendee.new(default_attendee_params.merge(attendee_params)) }

  describe '#has_skype?' do
    subject { attendee.has_skype? }

    context 'when skype is present' do
      let(:attendee_params) { { skype_id: 'bob.juliedesk' } }
      it { is_expected.to eq(true) }
    end

    context 'when skype is not present' do
      let(:attendee_params) { { skype_id: nil } }
      it { is_expected.to eq(false) }
    end
  end


  describe '#merge_with!' do
    let(:options) { { } }
    let(:original_attendee_params) { { } }
    let(:original_attendee) { Attendee.new({email: 'bob@juliedesk.com'}.merge(original_attendee_params)) }

    let(:new_attendee_params) { { } }
    let(:new_attendee) do
      Attendee.new({
          email: 'bob@juliedesk.com', first_name: 'Bob', last_name: 'Doe', usage_name: 'Bobby', gender: 'M', landline: '0102030405',
          mobile: '0602030405', skype_id: 'bob.doe', company: 'Julie Desk', is_present: true, status: 'present', is_client: false, assisted: false,
          is_assistant: false, is_thread_owner: false, confcall_instructions: 'Appeler au +33102030405'
      }.merge(new_attendee_params))
    end

    subject { original_attendee.merge_with!(new_attendee, options) ; original_attendee }

    context 'when only new values' do
      it { is_expected.to have_attributes(email: 'bob@juliedesk.com') }
      it { is_expected.to have_attributes(first_name: 'Bob') }
      it { is_expected.to have_attributes(last_name: 'Doe') }
      it { is_expected.to have_attributes(usage_name: 'Bobby') }
      it { is_expected.to have_attributes(gender: 'M') }
      it { is_expected.to have_attributes(landline: '0102030405') }
      it { is_expected.to have_attributes(mobile: '0602030405') }
      it { is_expected.to have_attributes(skype_id: 'bob.doe') }
      it { is_expected.to have_attributes(company: 'Julie Desk') }
      it { is_expected.to have_attributes(is_present: true) }
      it { is_expected.to have_attributes(status: 'present') }
      it { is_expected.to have_attributes(is_client: false) }
      it { is_expected.to have_attributes(assisted: false) }
      it { is_expected.to have_attributes(is_assistant: false) }
      it { is_expected.to have_attributes(is_thread_owner: false) }
      it { is_expected.to have_attributes(confcall_instructions: 'Appeler au +33102030405') }
    end

    context 'when original attendee already has a specific attributes' do
      let(:original_attendee_params) { { first_name: 'Robert' } }
      it 'does not override it' do
        is_expected.to have_attributes(first_name: 'Robert')
      end
    end

    context 'when overwrite option is present' do
      let(:options) { { overwrite: true } }
      let(:original_attendee_params) { { first_name: 'Robert' } }
      it 'does not override it' do
        is_expected.to have_attributes(first_name: 'Bob')
      end
    end
  end


  describe '.merge!' do
    let(:existing_attendee) { Attendee.new(email: 'bob@juliedesk.com', first_name: 'Robert', last_name: 'Doe') }
    let(:existing_attendees) { [existing_attendee] }

    let(:new_attendees) do
      [
          Attendee.new(email: 'john@company.com', first_name: 'John', last_name: 'Wayne'),
          Attendee.new(email: 'bob@juliedesk.com', first_name: 'Bob', landline: '0102030405', mobile: '0602030405'),
      ]
    end

    subject { Attendee.merge!(existing_attendees, new_attendees) ; existing_attendees }

    it 'adds new attendees' do
      is_expected.to include(an_object_having_attributes(email: 'john@company.com', first_name: 'John', last_name: 'Wayne'))
    end

    it 'update existing attendees' do
      is_expected.to include(an_object_having_attributes(email: 'bob@juliedesk.com', first_name: 'Robert', last_name: 'Doe', landline: '0102030405', mobile: '0602030405'))
    end
  end

  describe '.from_json' do
    let(:json_data) { "[{\"guid\":\"153463\",\"email\":\"bob@juliedesk.com\",\"firstName\":\"Robert\",\"lastName\":\"Doe\",\"name\":\"Bob Doe\",\"usageName\":\"Bobby\",\"gender\":\"M\",\"isAssistant\":\"false\",\"assisted\":\"false\",\"assistedBy\":\"\",\"company\":\"Julie Desk\",\"timezone\":\"Europe/Paris\",\"landline\":\"0102030405\",\"mobile\":\"0602030405\",\"skypeId\":\"bob.doe\",\"confCallInstructions\":\"\",\"status\":\"present\",\"isPresent\":\"true\",\"isClient\":\"false\",\"isThreadOwner\":\"false\",\"needAIConfirmation\":\"false\",\"aIHasBeenConfirmed\":\"true\",\"confCallInstructions\":\"Appeler au +33102030405\"}]" }
    subject { Attendee.from_json(json_data) }

    context 'when json is an array' do
      it { is_expected.to include(an_object_having_attributes(account_email: nil)) }
      it { is_expected.to include(an_object_having_attributes(email: 'bob@juliedesk.com')) }
      it { is_expected.to include(an_object_having_attributes(first_name: 'Robert')) }
      it { is_expected.to include(an_object_having_attributes(last_name: 'Doe')) }
      it { is_expected.to include(an_object_having_attributes(usage_name: 'Bobby')) }
      it { is_expected.to include(an_object_having_attributes(gender: 'M')) }
      it { is_expected.to include(an_object_having_attributes(is_present: true)) }
      it { is_expected.to include(an_object_having_attributes(status: 'present')) }
      it { is_expected.to include(an_object_having_attributes(company: 'Julie Desk')) }
      it { is_expected.to include(an_object_having_attributes(landline: '0102030405')) }
      it { is_expected.to include(an_object_having_attributes(mobile: '0602030405')) }
      it { is_expected.to include(an_object_having_attributes(skype_id: 'bob.doe')) }
      it { is_expected.to include(an_object_having_attributes(is_client: false)) }
      it { is_expected.to include(an_object_having_attributes(assisted: false)) }
      it { is_expected.to include(an_object_having_attributes(is_assistant: false)) }
      it { is_expected.to include(an_object_having_attributes(confcall_instructions: 'Appeler au +33102030405')) }
    end

  end


end
