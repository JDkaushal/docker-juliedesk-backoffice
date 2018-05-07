require "rails_helper"

describe AutomaticProcessing::Flows::CallInstructions, class: 'AutomaticProcessing::Flows::CallInstructions' do
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
    {
        'email' => account.email, 'firstName' => 'Bob', 'lastName' => 'Doe', 'skypeId' => account.skype, 'isPresent' => 'true',
        'isClient' => 'true', 'isThreadOwner' => 'true', 'company' => 'Julie Desk', 'landline' => account.landline_number, 'mobile' => account.mobile_number
    }.merge(client_attendee_params)
  end

  let(:attendee_params) { { } }
  let(:attendee) do
    { 'email' => 'john@somecompany.com', 'firstName' => 'John', 'lastName' => 'Doe', 'skypeId' => 'john.doe', 'isPresent' => 'true', 'isClient' => 'false' }.merge(attendee_params)
  end
  let(:attendees) { [client_attendee, attendee] }

  let(:classification_params) { {  } }
  let(:classification) { create(:automated_message_classification, { attendees: attendees.to_json }.merge(classification_params)) }
  let(:flow_processor) { AutomaticProcessing::Flows::CallInstructions.new(classification: classification) }

  before(:each) {
    allow(classification).to receive(:account).and_return(account)
  }

  describe '#process_flow' do
    let(:action_nature) { nil }
    subject { flow_processor.process_flow('GET_CALL_INSTRUCTIONS') }


    context 'when no behaviour' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => '01222222',  'appointments' => [ { 'kind' => 'call', 'behaviour' => nil } ] }
      end

      it { is_expected.to include(target: 'later', support: '', targetInfos: { } )}
    end

    context 'when call with behaviour propose and support is Landline (available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => '01222222',  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'landline', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '01222222')}
    end


    # TODO : strange (support should be mobile because we ask for :any_number in julie_action_required_data_for_location flow)
    context 'when call with behaviour propose and support is Landline (mobile only available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => nil, 'mobile_number' => '06222222',  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'landline', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '')}
    end

    context 'when call with behaviour propose and support is Landline (no number available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => nil, 'mobile_number' => nil,  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'landline', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '')}
    end



    context 'when call with behaviour propose and support is Mobile (available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'mobile_number' => '06222222',  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'mobile', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '06222222')}
    end

    # TODO : strange (support should be landline because we ask for :any_number in julie_action_required_data_for_location flow)
    context 'when call with behaviour is propose and support is Mobile (mobile not available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => '01222222', 'mobile_number' => nil,  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'mobile', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '')}
    end

    context 'when call with behaviour propose and support is Mobile (no number available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => nil, 'mobile_number' => nil,  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'mobile', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '')}
    end




    context 'when skype with behaviour propose and support is Skype (available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:account_params) do
        { 'skype' => 'bob.doe',  'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Skype' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'skype', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: 'bob.doe')}
    end


    context 'when skype with behaviour propose and support is Skype (skype not available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:account_params) do
        { 'skype' => nil,  'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Skype' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'skype', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' }, details: '')}
    end




    context 'when skype with behaviour propose and support is Skype For Business (skype available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:account_params) do
        { 'skype' => 'bob.doe',  'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Skype For Business' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'skype_for_business', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end


    context 'when skype with behaviour propose and support is Skype For Business (skype not available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:account_params) do
        { 'skype' => nil,  'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Skype For Business' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'skype_for_business', targetInfos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end




    context 'when call with behaviour ask interlocutor (landline & mobile available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => '06333333' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', targetInfos: { email: 'john@somecompany.com', name: 'John Doe' }, details: '06333333')}
    end


    context 'when call with behaviour ask interlocutor (full name not available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => '06333333', 'firstName' => '', 'lastName' => '' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', targetInfos: { email: 'john@somecompany.com', name: 'john@somecompany.com' }, details: '06333333')}
    end


    context 'when call with behaviour ask interlocutor (landline available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'landline', targetInfos: { email: 'john@somecompany.com', name: 'John Doe' }, details: '01333333')}
    end

    context 'when call with behaviour ask interlocutor (mobile available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => nil, 'mobile' => '06333333' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', targetInfos: { email: 'john@somecompany.com', name: 'John Doe' }, details: '06333333')}
    end


    context 'when call with behaviour ask interlocutor (no number available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => nil, 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: '', targetInfos: { email: 'john@somecompany.com', name: 'John Doe' }, details: '')}
    end


    # Fallback purpose (call with more than 2 attendees is a confcall)
    context 'when call with behaviour ask interlocutor (more than 2 attendees)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendees) do
        [
            { 'email' => 'bob@julidesk.com', 'isPresent' => 'true', 'isThreadOwner' => 'true', 'isClient' => 'true' },
            { 'email' => 'john@somecompany.com', 'isPresent' => 'true', 'mobile' => '0602030405' },
            { 'email' => 'roger@somecompany.com', 'isPresent' => 'true' }
        ]
      end
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: '', targetInfos: {}, details: '')}
    end





    # TODO: check
    context 'when behaviour is ask interlocutor for skype (landline & mobile available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => '06333333', 'skype' => 'john.doe' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', targetInfos: { email: 'john@somecompany.com', name: 'John Doe' }, details: '06333333')}
    end

    # TODO: check
    context 'when behaviour is ask interlocutor for skype and landline available' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => nil, 'skype' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'landline', targetInfos: { email: 'john@somecompany.com', name: 'John Doe' }, details: '01333333')}
    end

    # TODO : check
    context 'when behaviour is ask interlocutor for skype (no number available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => nil, 'mobile' => nil, 'skype' => 'john.doe' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Demander à l\'interlocuteur' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: '', targetInfos: { email: 'john@somecompany.com', name: 'John Doe' }, details: '')}
    end



    context 'when behaviour is ask later' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'later', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'later', support: '', targetInfos: {}, details: '')}
    end


  end

end