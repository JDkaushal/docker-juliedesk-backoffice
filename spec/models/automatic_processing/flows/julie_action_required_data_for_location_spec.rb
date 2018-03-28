require "rails_helper"

describe AutomaticProcessing::Flows::JulieActionRequiredDataForLocation, class: 'AutomaticProcessing::Flows::JulieActionRequiredDataForLocation' do
  let(:account_params) { { } }
  let(:account) do
    account = Account.new
    account_params.each do |k, v|
      account.send("#{k}=", v)
    end
    account
  end

  let(:message_classification_params) { {  } }
  let(:message_classification) { create(:automated_message_classification, message_classification_params) }
  let(:flow_processor) { AutomaticProcessing::Flows::JulieActionRequiredDataForLocation.new(classification: message_classification, account: account) }


  describe '#process_flow' do
    let(:action_nature) { nil }
    subject { flow_processor.process_flow(action_nature) }


    context 'when ask suggestions ' do
      let(:action_nature) { JulieAction::JD_ACTION_SUGGEST_DATES }

      context 'for an appointment and default address is present' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'appointment', 'default_address' => { 'label' => '15b boulevard Saint-Denis 75002 Paris' } } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'appointment' } }


        it { is_expected.to match_array([{field: :location, required_from: :anyone}]) }
      end

      context 'for an appointment and default address is ask interlocutor ' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'appointment', 'default_address' => { 'label' => 'A choisir par l\'interlocuteur' } } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'appointment' } }


        it { is_expected.to match_array([{field: :location, required_from: :anyone}]) }
      end


      context 'for an appointment and default address is None' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'appointment', 'default_address' => { 'label' => '' } } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'appointment' } }


        it { is_expected.to match_array([{field: :location, required_from: :anyone}]) }
      end


      context 'for an appointment (decide location later)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'appointment', 'default_address' => { 'label' => 'Le client choisira plus tard' } } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'appointment' } }

        it { is_expected.to match_array([]) }
      end



      context 'for a skype meeting (propose)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'skype', 'behaviour' => 'propose' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'skype' } }

        it { is_expected.to match_array([{field: :skype, required_from: :thread_owner}]) }
      end


      context 'for a skype meeting (ask later)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'skype', 'behaviour' => 'later' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'skype' } }

        it { is_expected.to match_array([]) }
      end

      context 'for a skype meeting (ask interlocutor)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'skype' } }

        it { is_expected.to match_array([{field: :skype, required_from: :attendees}]) }
      end



      context 'for a call (propose)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'call', 'behaviour' => 'propose' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'call' } }

        it { is_expected.to match_array([{field: :any_number, required_from: :thread_owner}]) }
      end


      context 'for a call (ask later)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'call', 'behaviour' => 'later' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'call' } }

        it { is_expected.to match_array([]) }
      end


      context 'for a call (ask interlocutor)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'call' } }

        it { is_expected.to match_array([{field: :any_number, required_from: :attendees}]) }
      end
    end



    # check availabilities
    context 'when check availabilities ' do
      let(:action_nature) { JulieAction::JD_ACTION_CHECK_AVAILABILITIES }

      context 'for an appointment' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'appointment', 'default_address' => { 'label' => '15b boulevard Saint-Denis 75002 Paris' } } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'appointment' } }


        it { is_expected.to match_array([{field: :location, required_from: :anyone}]) }
      end


      context 'for an appointment (decide location later)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'appointment', 'default_address' => { 'label' => 'Le client choisira plus tard' } } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'appointment' } }

        it { is_expected.to match_array([]) }
      end



      context 'for a skype meeting (propose)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'skype', 'behaviour' => 'propose' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'skype' } }

        it { is_expected.to match_array([{field: :skype, required_from: :thread_owner}]) }
      end


      context 'for a skype meeting (ask later)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'skype', 'behaviour' => 'later' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'skype' } }

        it { is_expected.to match_array([]) }
      end

      context 'for a skype meeting (ask interlocutor)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'skype', 'behaviour' => 'ask_interlocutor' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'skype' } }

        it { is_expected.to match_array([{field: :skype, required_from: :attendees}]) }
      end



      context 'for a call (propose)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'call', 'behaviour' => 'propose' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'call' } }

        it { is_expected.to match_array([{field: :any_number, required_from: :thread_owner}]) }
      end


      context 'for a call (ask later)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'call', 'behaviour' => 'later' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'call' } }

        it { is_expected.to match_array([]) }
      end


      context 'for a call (ask interlocutor)' do
        let(:account_params) do
          { email: 'bob@juliedesk.com', appointments: [ { 'kind' => 'call', 'behaviour' => 'ask_interlocutor' } ] }
        end
        let(:message_classification_params) { { appointment_nature: 'call' } }

        it { is_expected.to match_array([{field: :any_number, required_from: :attendees}]) }
      end
    end


  end

end