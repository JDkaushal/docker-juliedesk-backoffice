require "rails_helper"

describe DelegatedSegmentClient do
  subject { DelegatedSegmentClient.new(SimpleSegment::Client.new({write_key: ENV['SEGMENT_WRITE_KEY']})) }

  context 'In a staging env' do
    before(:example) do
      ENV['STAGING_APP'] = 'TRUE'
    end

    describe 'track' do
      it 'should not call the original method' do
        expect_any_instance_of(SimpleSegment::Client).not_to receive(:track)
        subject.track({data: 'test'})
      end
    end
  end

  context 'Not in a staging env' do
    before(:example) do
      ENV['STAGING_APP'] = nil
    end

    describe 'track' do
      let(:data) { {data: 'test'} }
      it 'should call the original method' do
        expect_any_instance_of(SimpleSegment::Client).to receive(:track).with(data)
        subject.track(data)
      end
    end
  end
end