require "rails_helper"

describe DashboardDataGenerator do

  describe 'generate_inbox_count_data' do

    it 'should return 0 messages threads count when no threads in inbox' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count)

      expect(DashboardDataGenerator.generate_inbox_count_data).to eq({
                                                                         :"count" => 0,
                                                                         :"admin_count" => 0,
                                                                         :"global_productivity" => 0,
                                                                         :"individual_productivity" => nil,
                                                                         :"current_delay" => 0,
                                                                         :"priority_count" => 0,
                                                                         :"follow_up_messages_threads_priority" => 0,
                                                                         :"follow_up_messages_threads_main" => 0
                                                                     })
    end

    it 'should return the messages threads for admin count when there are threads in inbox that are not delegated to founders and no accounts are retrieved from the redis accounts cache ' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      expect(DashboardDataGenerator.generate_inbox_count_data).to eq({
                                                                         :"count" => 0,
                                                                         :"admin_count" => 5,
                                                                         :"global_productivity" => 0,
                                                                         :"individual_productivity" => nil,
                                                                         :"current_delay" => 0,
                                                                         :"priority_count" => 0,
                                                                         :"follow_up_messages_threads_priority" => 0,
                                                                         :"follow_up_messages_threads_main" => 0
                                                                     })
    end

    it 'should return the messages threads for admin count when there are threads in inbox that are delegated to founders' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_sent_to_admin_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_sent_to_admin_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_sent_to_admin_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_sent_to_admin_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_sent_to_admin_in_inbox)


      expect(DashboardDataGenerator.generate_inbox_count_data).to eq({
                                                                         :"count" => 0,
                                                                         :"admin_count" => 5,
                                                                         :"global_productivity" => 0,
                                                                         :"individual_productivity" => nil,
                                                                         :"current_delay" => 0,
                                                                         :"priority_count" => 0,
                                                                         :"follow_up_messages_threads_priority" => 0,
                                                                         :"follow_up_messages_threads_main" => 0
                                                                     })
    end

    it 'should return the messages threads for admin count when there are threads in inbox that have an account set to only_admin_can_process or that have no accounts founds in the cache' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => true}, mt2.account_email => {"only_admin_can_process" => true}, mt3.account_email => {"only_admin_can_process" => true}})

      expect(DashboardDataGenerator.generate_inbox_count_data).to eq({
                                                                         :"count" => 0,
                                                                         :"admin_count" => 5,
                                                                         :"global_productivity" => 0,
                                                                         :"individual_productivity" => nil,
                                                                         :"current_delay" => 0,
                                                                         :"priority_count" => 0,
                                                                         :"follow_up_messages_threads_priority" => 0,
                                                                         :"follow_up_messages_threads_main" => 0
                                                                     })
    end

    it 'should return the correct messages threads count when there are threads in inbox that have an account found in the cache' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt2.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt3.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt4.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt5.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}})

      expect(DashboardDataGenerator.generate_inbox_count_data).to eq({
                                                                         :"count" => 5,
                                                                         :"admin_count" => 0,
                                                                         :"global_productivity" => 0,
                                                                         :"individual_productivity" => nil,
                                                                         :"current_delay" => 0,
                                                                         :"priority_count" => 0,
                                                                         :"follow_up_messages_threads_priority" => 0,
                                                                         :"follow_up_messages_threads_main" => 0
                                                                     })
    end

    it 'should return the correct messages threads count when there are threads in inbox that have an account found in the cache but some have companies working hours out of bounds' do
      mt1 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt2 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt3 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt4 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)
      mt5 = FactoryGirl.create(:messages_thread_for_inbox_count_in_inbox)

      allow(DateTime).to receive(:now).and_return(DateTime.new(2015, 11, 25, 12, 00, 00))

      allow(Account).to receive(:accounts_cache).and_return({mt1.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['0', '1100']}}}}, mt2.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['1300', '2400']}}}}, mt3.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n', 'company_hash' => {'timezone' => 'UTC', 'working_hours' => {'wed' => {0 => ['800', '1800']}}}}, mt4.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}, mt5.account_email => {"only_admin_can_process" => false, 'full_name' => 'f n'}})

      expect(DashboardDataGenerator.generate_inbox_count_data).to eq({
                                                                         :"count" => 3,
                                                                         :"admin_count" => 0,
                                                                         :"global_productivity" => 0,
                                                                         :"individual_productivity" => nil,
                                                                         :"current_delay" => 0,
                                                                         :"priority_count" => 0,
                                                                         :"follow_up_messages_threads_priority" => 0,
                                                                         :"follow_up_messages_threads_main" => 0
                                                                     })
    end
  end

  describe 'generate_operators_count_at_time_data' do
    before(:each) do
      expect(DateTime).to receive(:now).and_return(DateTime.new(2015, 11, 25, 12, 23, 00))
    end

    it 'should return the correct values' do
      op1 = FactoryGirl.create(:operator_actif)
      op2 = FactoryGirl.create(:operator_actif)
      op3 = FactoryGirl.create(:operator_actif)
      op4 = FactoryGirl.create(:operator_actif)
      op5 = FactoryGirl.create(:operator_actif)

      op1.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
      op2.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
      op3.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
      op4.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
      op5.operator_presences.create(date: DateTime.new(2015, 11, 25, 12, 00, 00))
      op5.operator_presences.create(date: DateTime.new(2015, 11, 26, 16, 00, 00), is_review: true)

      expect(DashboardDataGenerator).to receive(:get_connected_to_socket_user_emails).and_return([op1.email, op2.email, op3.email, op4.email, op5.email])

      expect(DashboardDataGenerator.generate_operators_count_at_time_data).to eq({
                                                                                     :"operators_count" => 5,
                                                                                     :"operators" => [
                                                                                         {:"name" => "operatorName1", :"email" => "person1@example.com", :"present" => true, :"privilege" => nil, :"operator_of_the_month" => false, :"operator_id" => 1},
                                                                                         {:"name" => "operatorName2", :"email" => "person2@example.com", :"present" => true, :"privilege" => nil, :"operator_of_the_month" => false, :"operator_id" => 2},
                                                                                         {:"name" => "operatorName3", :"email" => "person3@example.com", :"present" => true, :"privilege" => nil, :"operator_of_the_month" => false, :"operator_id" => 3},
                                                                                         {:"name" => "operatorName4", :"email" => "person4@example.com", :"present" => true, :"privilege" => nil, :"operator_of_the_month" => false, :"operator_id" => 4},
                                                                                         {:"name" => "operatorName5", :"email" => "person5@example.com", :"present" => true, :"privilege" => nil, :"operator_of_the_month" => false, :"operator_id" => 5}
                                                                                     ]
                                                                                 })
    end
  end
end
