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

  describe '.from_json' do
    let(:json_data) { "[{\"guid\":\"153463\",\"email\":\"bob@juliedesk.com\",\"firstName\":\"Robert\",\"lastName\":\"Doe\",\"name\":\"Bob Doe\",\"usageName\":\"Bobby\",\"gender\":\"M\",\"isAssistant\":\"false\",\"assisted\":\"false\",\"assistedBy\":\"\",\"company\":\"Julie Desk\",\"timezone\":\"Europe/Paris\",\"landline\":\"0102030405\",\"mobile\":\"0602030405\",\"skypeId\":\"bob.doe\",\"confCallInstructions\":\"\",\"status\":\"present\",\"isPresent\":\"true\",\"isClient\":\"false\",\"isThreadOwner\":\"false\",\"needAIConfirmation\":\"false\",\"aIHasBeenConfirmed\":\"true\"}]" }
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
    end

  end


end
