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
    { 'email' => 'bob@juliedesk.com', 'firstName' => 'Bob', 'lastName' => 'Doe', 'skypeId' => 'bob.doe', 'isPresent' => 'true', 'isClient' => 'true', 'isThreadOwner' => 'true', 'company' => 'Julie Desk'  }.merge(client_attendee_params)
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


    context 'when behaviour is propose and support is Landline (available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => '01222222',  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'landline', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end


    # TODO : strange (support should be mobile because we ask for :any_number in julie_action_required_data_for_location flow)
    context 'when behaviour is propose and support is Landline (mobile only available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => nil, 'mobile_number' => '06222222',  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'landline', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end

    context 'when behaviour is propose and support is Landline (no number available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => nil, 'mobile_number' => nil,  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'landline', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end



    context 'when behaviour is propose and support is Mobile (available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'mobile_number' => '06222222',  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'mobile', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end

    # TODO : strange (support should be landline because we ask for :any_number in julie_action_required_data_for_location flow)
    context 'when behaviour is propose and support is Mobile (mobile not available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => '01222222', 'mobile_number' => nil,  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'mobile', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end

    context 'when behaviour is propose and support is Mobile (no number available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:account_params) do
        { 'landline_number' => nil, 'mobile_number' => nil,  'appointments' => [ { 'kind' => 'call', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'mobile', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end




    context 'when behaviour is propose and support is Skype (available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:account_params) do
        { 'skype' => 'bob.doe',  'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Skype' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'skype', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end


    context 'when behaviour is propose and support is Skype (skype not available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:account_params) do
        { 'skype' => nil,  'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Skype' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'skype', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end




    context 'when behaviour is propose and support is Skype For Business (skype available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:account_params) do
        { 'skype' => 'bob.doe',  'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Skype For Business' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'skype_for_business', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end


    context 'when behaviour is propose and support is Skype For Business (skype not available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:account_params) do
        { 'skype' => nil,  'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'propose', 'support_config_hash' => { 'label' => 'Skype For Business' } } ] }
      end

      it { is_expected.to include(target: 'client', support: 'skype_for_business', target_infos: { email: 'bob@juliedesk.com', name: 'Bob Doe' })}
    end




    context 'when behaviour is ask interlocutor and support is Landline (landline and mobile available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => '06333333' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end


    context 'when behaviour is ask interlocutor and support is Landline (available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'landline', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end

    context 'when behaviour is ask interlocutor and support is Landline (mobile only available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => nil, 'mobile' => '06333333' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end


    # TODO: strange (sometimes we favor mobile over landline and sometimes we don't)
    context 'when behaviour is ask interlocutor and support is Landline (no number available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => nil, 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'landline', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end



    context 'when behaviour is ask interlocutor and support is Landline (more than 2 attendees)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendees) do
        [
            { 'email' => 'bob@julidesk.com', 'isPresent' => 'true', 'isThreadOwner' => 'true', 'isClient' => 'true' },
            { 'email' => 'john@somecompany.com', 'isPresent' => 'true' },
            { 'email' => 'roger@somecompany.com', 'isPresent' => 'true' }
        ]
      end
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'landline', target_infos: {})}
    end




    context 'when behaviour is ask interlocutor and support is Mobile (available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'mobile' => '06333333' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end

    context 'when behaviour is propose and support is Mobile (landline only available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'landline', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end

    context 'when behaviour is propose and support is Mobile (no number available)' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => nil, 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Mobile' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: '', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end



    # TODO: strange (support should be skype ?)
    context 'when behaviour is ask interlocutor and support is Skype (available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => '06333333', 'skype' => 'john.doe' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Skype' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end

    # TODO: strange (support should be skype ? )
    context 'when behaviour is ask interlocutor and support is Skype (landline only available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => nil, 'skype' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Skype' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'landline', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end

    context 'when behaviour is propose and support is Skype (no number available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => nil, 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Skype' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'skype', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end



    context 'when behaviour is ask interlocutor and support is Skype For Business (skype available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => '06333333', 'skype' => 'john.doe' } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Skype For Business' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'mobile', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end

    # TODO: strange (suppoort should be skype ?)
    context 'when behaviour is propose and support is Skype For Business (landline only available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => nil, 'skype' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Skype For Business' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'landline', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end

    context 'when behaviour is propose and support is Skype (no number available)' do
      let(:classification_params) { { appointment_nature: 'skype' } }
      let(:attendee_params) { { 'landline' => nil, 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor', 'support_config_hash' => { 'label' => 'Skype For Business' } } ] }
      end

      it { is_expected.to include(target: 'interlocutor', support: 'skype_for_business', target_infos: { email: 'john@somecompany.com', name: 'John Doe' })}
    end



    context 'when behaviour is ask later' do
      let(:classification_params) { { appointment_nature: 'call' } }
      let(:attendee_params) { { 'landline' => '01333333', 'mobile' => nil } }
      let(:account_params) do
        { 'appointments' => [ { 'kind' => 'call', 'behaviour' => 'later', 'support_config_hash' => { 'label' => 'Landline' } } ] }
      end

      it { is_expected.to include(target: 'later', support: '', target_infos: {})}
    end


  end

end