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


end