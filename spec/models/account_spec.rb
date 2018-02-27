require "rails_helper"

describe Account do
  let(:account_params) { {} }
  let(:default_account_params) { {} }

  let(:account) do
    acc = Account.new
    default_account_params.merge(account_params).each do |attr_name, value|
      acc.send("#{attr_name}=", value)
    end
    acc
  end

  shared_context 'now it is' do |time_string|
    let(:current_time) { Time.parse(time_string) }
    before(:example) do
      allow(Time).to receive(:now).and_return(current_time.utc)
    end
  end

  describe '#can_be_followed_up_now?' do
    subject { account.can_be_followed_up_now? }

    context 'when current account time is before 8:30' do
      include_context 'now it is', 'Fri, 23 Feb 2018 07:30:00 PST -08:00'
      let(:account_params) { { default_timezone_id: 'America/Los_Angeles' } }

      it { is_expected.to eq(false) }
    end

    context 'when current account time is after 18:30' do
      include_context 'now it is', 'Fri, 23 Feb 2018 19:30:00 PST -08:00'
      let(:account_params) { { default_timezone_id: 'America/Los_Angeles' } }

      it { is_expected.to eq(false) }
    end

    context 'when current account time is between 8:30 and 18:30' do
      include_context 'now it is', 'Fri, 23 Feb 2018 15:30:00 PST -08:00'
      let(:account_params) { { default_timezone_id: 'America/Los_Angeles' } }

      it { is_expected.to eq(true) }
    end

    context 'when current account date is a Saturday' do
      include_context 'now it is', 'Sat, 24 Feb 2018 15:30:00 PST -08:00'
      let(:account_params) { { default_timezone_id: 'America/Los_Angeles' } }

      it { is_expected.to eq(false) }
    end

    context 'when current account date is a Sunday' do
      include_context 'now it is', 'Sun, 25 Feb 2018 15:30:00 PST -08:00'
      let(:account_params) { { default_timezone_id: 'America/Los_Angeles' } }

      it { is_expected.to eq(false) }
    end
  end

end