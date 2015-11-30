require_relative "../../../rails_helper"

describe Api::V1::MessagesThreadsController, :type => :controller do

  describe 'Inheritance' do
    it { expect(described_class).to be < Api::ApiV1Controller }
  end

  describe 'inbox_count' do

    it 'should return 0 messages threads count when no threads in inbox' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count)

      path, params = ApiHelper.authenticated_request(:inbox_count)
      get path, params

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":0,\"admin_count\":0}}")
    end

    it 'should return the messages threads for admin count when there are threads in inbox that are not delegated to founders and no accounts are retrieved from the redis accounts cache ' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      path, params = ApiHelper.authenticated_request(:inbox_count)
      get path, params

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":0,\"admin_count\":5}}")
    end

    it 'should return the messages threads for admin count when there are threads in inbox that are delegated to founders' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_delegated_to_founders_in_inbox)

      path, params = ApiHelper.authenticated_request(:inbox_count)
      get path, params

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":0,\"admin_count\":5}}")
    end

    it 'should return the messages threads for admin count when there are threads in inbox that have an account set to only_admin_can_process or that have no accounts founds in the cache' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => true}, mt2.account_email => {"only_admin_can_process" => true}, mt3.account_email => {"only_admin_can_process" => true}})

      path, params = ApiHelper.authenticated_request(:inbox_count)
      get path, params

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":0,\"admin_count\":5}}")
    end

    it 'should return the correct messages threads count when there are threads in inbox that have an account found in the cache' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt2.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt3.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt4.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt5.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}})

      path, params = ApiHelper.authenticated_request(:inbox_count)
      get path, params

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":5,\"admin_count\":0}}")
    end

    it 'should return the correct messages threads count when there are threads in inbox that have an account found in the cache but some have companies working hours out of bounds' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(DateTime).to receive(:now).and_return(DateTime.new(2015, 11, 25, 12, 00, 00))

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['0', '1100']}}}}, mt2.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['1300', '2400']}}}}, mt3.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['800', '1800']}}}}, mt4.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt5.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}})

      path, params = ApiHelper.authenticated_request(:inbox_count)
      get path, params

      expect(response.body).to eq("{\"status\":\"success\",\"data\":{\"count\":3,\"admin_count\":0}}")
    end
  end
end