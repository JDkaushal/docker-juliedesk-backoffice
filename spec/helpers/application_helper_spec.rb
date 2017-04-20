require "rails_helper"

describe ApplicationHelper do

  describe 'email_in_domain?' do
    let(:domains) { ['domain1.com', 'domain2.com'] }

    it 'should return true' do
      expect(ApplicationHelper.email_in_domain?(domains, 'email@domain2.com'))
    end

    it 'should return false' do
      expect(ApplicationHelper.email_in_domain?(domains, 'email@domain3.com'))
    end

  end

  describe '.find_addresses' do
    let(:content) { "" }
    subject { ApplicationHelper.find_addresses(content).addresses.first.try(:address) }

    context "when name contains special char ':'" do
      let(:content) { 'Bob Doe : Bob Doe <bob.doe@yopmail.com>' }
      it { is_expected.to eq('bob.doe@yopmail.com') }
    end
  end


end