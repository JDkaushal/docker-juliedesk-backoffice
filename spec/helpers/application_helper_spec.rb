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
    subject { ApplicationHelper.find_addresses(content).addresses.map(&:address) }

    context "when string contain only email" do
      let(:content) { 'bob.doe@yopmail.com' }
      it { is_expected.to eq(['bob.doe@yopmail.com']) }
    end

    context "when string contain email and name" do
      let(:content) { 'Bob <bob.doe@yopmail.com>' }
      it { is_expected.to eq(['bob.doe@yopmail.com']) }
    end

    context "when string contain multiple email and name" do
      let(:content) { 'John <john@yopmail.com>, Bob <bob.doe@yopmail.com>' }
      it { is_expected.to eq(['john@yopmail.com', 'bob.doe@yopmail.com']) }
    end

    context "when name contains special char ':'" do
      let(:content) { 'Bob Doe : Bob Doe <bob.doe@yopmail.com>' }
      it { is_expected.to eq(['bob.doe@yopmail.com']) }
    end

    context "when white space is present before name" do
      let(:content) { 'Bob Doe <bob.doe@yopmail.com>,  Johnny Doe <johnny.doe@yopmail.com>' }
      it { is_expected.to match_array(['bob.doe@yopmail.com', 'johnny.doe@yopmail.com']) }
    end

    context "when the name contain a comma" do
      let(:content) { '"Doe, Bob (Bob Commpany, Bob Group)" <bob.doe@yopmail.com>, Johnny <johnny.doe@yopmail.com>' }
      it { is_expected.to match_array(['bob.doe@yopmail.com', 'johnny.doe@yopmail.com']) }
    end

    context "when one of the recipient has no name (only email)" do
      let(:content) { 'bob.doe@yopmail.com, Johnny <johnny.doe@yopmail.com>' }
      it { is_expected.to match_array(['bob.doe@yopmail.com', 'johnny.doe@yopmail.com']) }
    end

    context "when name and email contain an apostrophe" do
      let(:content) { "\"d'Argentre,Alexis\" <Alexis.d'Argentre@gartner.com>" }
      it { is_expected.to match_array(["alexis.d'argentre@gartner.com"]) }
    end

    context "when name contains numbers" do
      let(:content) { "8765 <8765ttg@gmail.com>, Julie de Bourbon <julie.bourbon@hildebrandt-law.com>" }
      it { is_expected.to match_array(["8765ttg@gmail.com", "julie.bourbon@hildebrandt-law.com"]) }
    end

    context "when name contains ⎪" do
      let(:content) { "Nicolas JOB ⎪Carbookr <nicolas@carbookr.com>, Julie de Bourbon <julie.bourbon@hildebrandt-law.com>" }
      it { is_expected.to match_array(["julie.bourbon@hildebrandt-law.com", "nicolas@carbookr.com"]) }
    end

    context "when name contains °" do
      let(:content) { "BobCorp 360° <bob@bobcorp360.com>" }
      it { is_expected.to match_array(["bob@bobcorp360.com"]) }
    end

    context 'when name start with -' do
      let(:content) { "- bob <bob.artisans@wanadoo.fr>" }
      it { is_expected.to match_array(["bob.artisans@wanadoo.fr"]) }
    end

    context 'name contain =UTF-8' do
      let(:content) { "=UTF-8BRMOpc2lyw6kgQ291bGliYWx5= <bob@gmail.com>" }
      it { is_expected.to match_array(["bob@gmail.com"]) }
    end

  end


end