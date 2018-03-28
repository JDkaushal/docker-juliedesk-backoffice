require "rails_helper"

describe AutomaticProcessing::Flows::JulieActionComplementaryInfo, class: 'AutomaticProcessing::Flows::JulieActionComplementaryInfo' do
  let(:account_params) { { } }
  let(:default_account_params) { { 'email' => 'bob@juliedesk.com' } }
  let(:account) do
    account = Account.new
    default_account_params.merge(account_params).each do |k, v|
      account.send("#{k}=", v)
    end
    account
  end

  let(:client_attendee_params) { { } }
  let(:client_attendee) do
    { 'email' => 'bob@juliedesk.com', 'firstName' => 'Bob', 'lastName' => 'Doe', 'skypeId' => 'bob.doe', 'isPresent' => 'true', 'isClient' => 'true', 'isThreadOwner' => 'true', 'company' => 'Julie Desk'  }.merge(client_attendee_params)
  end

  let(:attendee_params) { { } }
  let(:attendee) do
    { 'email' => 'john@somecompany.com', 'firstName' => 'John', 'lastName' => 'Doe', 'skypeId' => 'john.doe', 'isPresent' => 'true', 'isClient' => 'false' }.merge(attendee_params)
  end
  let(:attendees) { [client_attendee, attendee] }

  let(:classification_params) { {  } }
  let(:classification) { create(:automated_message_classification, { attendees: attendees.to_json }.merge(classification_params)) }
  let(:flow_processor) { AutomaticProcessing::Flows::JulieActionComplementaryInfo.new(classification: classification, account: account) }

  before(:each) {
    allow(account).to receive(:company).and_return('Julie Desk')
    allow(classification).to receive(:account).and_return(account)
  }

  describe '#process_flow' do
    let(:action_nature) { nil }
    subject { flow_processor.process_flow(action_nature) }


    context 'when ask suggestions ' do
      let(:action_nature) { JulieAction::JD_ACTION_SUGGEST_DATES }
      let(:classification_params) { { appointment_nature: 'appointment' } }

      context 'and no attendee has mobile (mobile_only required)' do
        let(:attendee_params) { { 'landline' => '01222222', 'mobile' => nil, 'isPresent' => 'true', 'company' => 'Some Company' } }
        let(:account_params) do
          { appointments: [ { 'kind' => 'appointment', 'required_additional_informations' => 'mobile_only' } ] }
        end

        it { is_expected.to eq({field: 'mobile', ask: :attendees}) }
      end


      context 'and no present attendee has mobile (mobile_only required)' do
        let(:attendee_params) { { 'landline' => '01222222', 'mobile' => '06222222', 'isPresent' => 'false', 'company' => 'Some Company' } }
        let(:account_params) do
          { appointments: [ { 'kind' => 'appointment', 'required_additional_informations' => 'mobile_only' } ] }
        end

        it { is_expected.to eq({field: 'mobile', ask: :attendees}) }
      end


      context 'and no present attendee from other company has mobile (mobile_only required)' do
        let(:attendee_params) { { 'landline' => '01222222', 'mobile' => '06222222', 'isPresent' => 'true', 'company' => 'Julie Desk' } }
        let(:account_params) do
          { appointments: [ { 'kind' => 'appointment', 'required_additional_informations' => 'mobile_only' } ] }
        end

        it { is_expected.to eq({field: 'mobile', ask: :attendees}) }
      end

      context 'and a present attendee from other company has mobile (mobile_only required)' do
        let(:attendee_params) { { 'landline' => '01222222', 'mobile' => '06222222', 'isPresent' => 'true', 'company' => 'Some Company' } }
        let(:account_params) do
          { appointments: [ { 'kind' => 'appointment', 'required_additional_informations' => 'mobile_only' } ] }
        end

        it { is_expected.to eq(nil) }
      end






      context 'and no attendee has a skype id (skype_only required)' do
        let(:classification_params) { { appointment_nature: 'skype' } }
        let(:attendee_params) { { 'skypeId' => nil, 'isPresent' => 'true', 'company' => 'Some Company' } }
        let(:account_params) do
          { appointments: [ { 'kind' => 'skype', 'required_additional_informations' => 'skype_only' } ] }
        end

        it { is_expected.to eq({field: 'skype', ask: :attendees}) }
      end


      context 'and no present attendee has skype (skype_only required)' do
        let(:classification_params) { { appointment_nature: 'skype' } }
        let(:attendee_params) { { 'skypeId' => 'john.doe', 'isPresent' => 'false', 'company' => 'Some Company' } }
        let(:account_params) do
          { appointments: [ { 'kind' => 'skype', 'required_additional_informations' => 'skype_only' } ] }
        end

        it { is_expected.to eq({field: 'skype', ask: :attendees}) }
      end


      context 'and no present attendee from other company has mobile (mobile_only required)' do
        let(:classification_params) { { appointment_nature: 'skype' } }
        let(:attendee_params) { { 'skypeId' => 'john.doe', 'isPresent' => 'true', 'company' => 'Julie Desk' } }
        let(:account_params) do
          { appointments: [ { 'kind' => 'skype', 'required_additional_informations' => 'skype_only' } ] }
        end

        it { is_expected.to eq({field: 'skype', ask: :attendees}) }
      end

      context 'and a present attendee from other company has mobile (mobile_only required)' do
        let(:classification_params) { { appointment_nature: 'skype' } }
        let(:attendee_params) { { 'skypeId' => 'john.doe', 'isPresent' => 'true', 'company' => 'Some Company' } }
        let(:account_params) do
          { appointments: [ { 'kind' => 'skype', 'required_additional_informations' => 'skype_only' } ] }
        end

        it { is_expected.to eq(nil) }
      end
    end


  end

end