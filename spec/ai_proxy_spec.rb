require "rails_helper"

describe AiProxy do

  describe 'get_endpoint' do

    describe 'parse_human_civilities' do
      it 'should return the correct values' do
        expect(AiProxy.get_endpoint(:parse_human_civilities)).to eq( { type: :get, url: 'test_ai_conscience_path_v3/firstlastnames/' } )
      end
    end

    describe 'get_company_name' do
      it 'should return the correct values' do
        expect(AiProxy.get_endpoint(:get_company_name)).to eq( { type: :post, url: 'test_ai_conscience_path_v1/companynames/' } )
      end
    end

    describe 'endpoint does not exists' do
      it 'should raise an error' do
        expect{
          AiProxy.get_endpoint(:dont_exist)
        }.to raise_error( AIEndPointUnknown, 'The specified endpoint has not been registered' )
      end
    end
  end

  describe 'build_request' do

    describe 'get request' do
      it 'should call the right methods' do
        proxy = AiProxy.new

        key = :test_key
        data = {key1: 'val1', key2: 'val2'}

        expect(AiProxy).to receive(:get_endpoint).with(key).and_return({ type: :get, url: 'http://test.com/api/v1' })
        expect(proxy).to receive(:set_url_params).with(URI.parse('http://test.com/api/v1'), data).and_return('url_formatted')
        expect(proxy).to receive(:dispatch_request).with(:get, 'url_formatted', data)

        proxy.build_request(key, data)
      end
    end

    describe 'post request' do
      it 'should call the right methods' do
        proxy = AiProxy.new

        key = :test_key
        data = {key1: 'val1', key2: 'val2'}

        expect(AiProxy).to receive(:get_endpoint).with(key).and_return({ type: :post, url: 'http://test.com/api/v1' })
        expect(proxy).not_to receive(:set_url_params)
        expect(proxy).to receive(:dispatch_request).with(:post, URI.parse('http://test.com/api/v1'), data)

        proxy.build_request(key, data)
      end
    end
  end

  describe 'dispatch_request' do
    before(:each) do
      @proxy = AiProxy.new
      @data = {key1: 'val1', key2: 'val2'}
      @url = 'test_url'

      @fake_client = HTTP.auth( ENV['CONSCIENCE_API_KEY'] )
    end

    describe 'get request' do
      it 'should call the right methods' do
        expect(HTTP).to receive(:auth).with(ENV['CONSCIENCE_API_KEY']).and_return(@fake_client)

        expect(@proxy).to receive(:execute_get_request).with(@fake_client, {url: @url, data: @data}).and_return("request get body")
        expect(@proxy).to receive(:format_response).with("request get body")

        @proxy.dispatch_request(:get, @url, @data)

        #expect(@fake_client.ssl_config.verify_mode).to eq(0)
      end
    end

    describe 'post request' do
      it 'should call the right methods' do
        expect(HTTP).to receive(:auth).with(ENV['CONSCIENCE_API_KEY']).and_return(@fake_client)

        expect(@proxy).to receive(:execute_post_request).with(@fake_client, {url: @url, data: @data}).and_return("request post body")
        expect(@proxy).to receive(:format_response).with("request post body")

        @proxy.dispatch_request(:post, @url, @data)

        #expect(@fake_client.ssl_config.verify_mode).to eq(0)
      end
    end
  end

  describe 'set_url_params' do
    before(:each) do
      @proxy = AiProxy.new
    end

    it 'should format the url correctly' do
      params = {key1: 'val1', key2: 'val2'}
      url = 'http://test.com'

      expect(@proxy.send(:set_url_params, URI.parse(url), params)).to eq(URI.parse('http://test.com?key1=val1&key2=val2'))
    end
  end

  describe 'format_response' do
    before(:each) do
      @proxy = AiProxy.new
    end

    it 'should parse the response' do
      response = HTTPResponseStub.new
      expect(response).to receive(:parse)

      @proxy.send(:format_response, response)
    end
  end

  describe 'execute_get_request' do
    before(:each) do
      @proxy = AiProxy.new

      @fake_client = HTTP.auth( ENV['CONSCIENCE_API_KEY'] )

      @params = {url: 'url', key2: 'val2'}
    end

    it 'should perform a get request to the correct url' do
      ssl = @proxy.send(:get_ssl_context)

      allow(@proxy).to receive(:get_ssl_context).and_return(ssl)

      expect(@fake_client).to receive(:get).with('url', ssl_context: ssl)
      @proxy.send(:execute_get_request, @fake_client, @params)
    end
  end

  describe 'execute_post_request' do
    before(:each) do
      @proxy = AiProxy.new

      @fake_client = HTTP.auth( ENV['CONSCIENCE_API_KEY'] )

      @params = {url: 'url', data: {key2: 'val2', key3: 'val3', key4: 'val4'}}
    end

    it 'should perform a get request to the correct url' do
      ssl = @proxy.send(:get_ssl_context)

      allow(@proxy).to receive(:get_ssl_context).and_return(ssl)

      expect(@fake_client).to receive(:post).with('url', json: {key2: 'val2', key3: 'val3', key4: 'val4'}, ssl_context: ssl)
      @proxy.send(:execute_post_request, @fake_client, @params)
    end
  end

  class HTTPResponseStub

    def code
      200
    end

    def parse
      #stub
    end

  end

end