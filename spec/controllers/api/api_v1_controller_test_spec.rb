require_relative "../../rails_helper"

describe Api::ApiV1Controller, :type => :controller do
  describe 'Inheritance' do
    it { expect(described_class).to be < ApiController }
  end
end