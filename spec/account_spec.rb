require "rails_helper"

describe Account do

  describe 'create_from_email' do
    context 'account cache is set' do
      before(:each) do
        @accounts_cache = {
            "email"=>"gabriel.cian@captainleads.com",
              "company_hash"=>
                {
                 "name"=>"CaptainLeads",
                 "timezone"=>"Europe/Paris",
                 "working_hours"=>
                     {
                         "mon"=>
                             {
                                 "0"=>["0", "2400"]
                             },
                         "tue"=>
                             {
                                 "0"=>["0", "2400"]
                             },
                         "wed"=>
                             {
                                 "0"=>["0", "2400"]
                             },
                         "thu"=>
                             {
                                 "0"=>["0", "2400"]
                             },
                         "fri"=>
                             {
                                 "0"=>["0", "2400"]
                             },
                         "sat"=>
                             {
                                 "0"=>["0", "2400"]
                             },
                         "sun"=>
                             {
                                 "0"=>["0", "2400"]
                             }
                     }
                 },
              "usage_name"=>"Gabriel",
              "full_name"=>"Gabriel Cian",
              "email_aliases"=>["gabriel.cian@progonline.com"],
              "office_365_refresh_token_expired"=>false,
              "only_admin_can_process"=>false,
              "only_support_can_process"=>false,
              "block_until_preferences_change"=>false,
              "is_pro"=>false
        }



      end




    end




  end

  describe "compute_rule" do
    it "should compute rule" do
      expect(Account.compute_rule nil, {
          email_alias: "nmarlier@gmail.com"
      }).to eq(Account::RULE_DEFAULT)
      expect(Account.compute_rule "", {
          email_alias: "nmarlier@gmail.com"
      }).to eq(Account::RULE_DEFAULT)

      expect(Account.compute_rule "EMAIL_ALIAS=nmarlier@gmail.com", {
          email_alias: "nmarlier@gmail.com"
      }).to eq(Account::RULE_VALIDATED)
      expect(Account.compute_rule "EMAIL_ALIAS=nmarlier@gmail.com|EMAIL_ALIAS=elrandil@gmail.com", {
          email_alias: "nmarlier@gmail.com"
      }).to eq(Account::RULE_VALIDATED)

      expect(Account.compute_rule "EMAIL_ALIAS=nmarlier@gmail.com|EMAIL_ALIAS=elrandil@gmail.com", {
          email_alias: "elrandil@gmail.com"
      }).to eq(Account::RULE_VALIDATED)
      expect(Account.compute_rule "EMAIL_ALIAS=nmarlier@gmail.com", {
          email_alias: "elrandil2@gmail.com"
      }).to eq(Account::RULE_UNVALIDATED)
      expect(Account.compute_rule "EMAIL_ALIAS=nmarlier@gmail.com|EMAIL_ALIAS=elrandil@gmail.com", {
          email_alias: "elrandil2@gmail.com"
      }).to eq(Account::RULE_UNVALIDATED)

    end
  end

  describe "find_calendar_login_with_rule" do
    context "all rules nil" do
      it "should get the calendar_login corresponding to rule" do
        account = Account.new

        google_login = {'username' => "nmarlier@gmail.com", 'rule' => nil, 'type' => "GoogleLogin"}
        exchange_login = {'username' => "nmarlier@gmail.com", 'rule' => nil, 'type' => "ExchangeLogin"}
        account.calendar_logins = [google_login, exchange_login]

        expect(account.find_calendar_login_with_rule_data({
                                                           email_alias: "nmarlier@gmail.com"
                                                       })).to eq(google_login)
        expect(account.find_calendar_login_with_rule_data({

                                                       })).to eq(google_login)
      end
    end

    context "one rule nil, the other set" do
      it "should get the calendar_login corresponding to rule" do
        account = Account.new
        google_login = {'username' => "nmarlier@gmail.com", 'rule' => nil, 'type' => "GoogleLogin"}
        exchange_login = {'username' => "nmarlier@gmail.com", 'rule' => "EMAIL_ALIAS=nmarlier@gmail.com", 'type' => "ExchangeLogin"}
        ews_login = {'username' => "nmarlier@gmail.com", 'rule' => "EMAIL_ALIAS=elrandil@gmail.com|EMAIL_ALIAS=nicolas@wepopp.com", 'type' => "ExchangeLogin"}
        account.calendar_logins = [google_login, exchange_login, ews_login]

        expect(account.find_calendar_login_with_rule_data({

                                                       })).to eq(google_login)
        expect(account.find_calendar_login_with_rule_data({
                                                           email_alias: "nmarlier@gmail.com"
                                                       })).to eq(exchange_login)
        expect(account.find_calendar_login_with_rule_data({
                                                           email_alias: "elrandil@gmail.com"
                                                       })).to eq(ews_login)
        expect(account.find_calendar_login_with_rule_data({
                                                           email_alias: "nicolas@wepopp.com"
                                                       })).to eq(ews_login)
        expect(account.find_calendar_login_with_rule_data({
                                                           email_alias: "nicolas2@wepopp.com"
                                                       })).to eq(google_login)
      end
    end

  end

  describe "migrate_account_email" do
    context "simple context - only account_email to update" do
      before do
        @messages_thread_1 = FactoryGirl.create(:messages_thread, account_email: "nicolas1@juliedesk.com")
        @messages_thread_2 = FactoryGirl.create(:messages_thread, account_email: "nicolas3@juliedesk.com")
      end

      it "should migrate all" do
        Account.migrate_account_email "nicolas1@juliedesk.com", "nicolas2@juliedesk.com"
        expect(MessagesThread.find(@messages_thread_1.id).account_email).to eq("nicolas2@juliedesk.com")
        expect(MessagesThread.find(@messages_thread_2.id).account_email).to eq("nicolas3@juliedesk.com")
      end
    end

    context "simple context - with attendees to update" do
      before do
        @messages_thread_1 = FactoryGirl.create(:messages_thread, account_email: "nicolas4@juliedesk.com")
        message_1 = FactoryGirl.create(:message, messages_thread: @messages_thread_1)
        attendees_1 = [
            {
                email: "julien@juliedesk.com"
            },
            {
                email: "nicolas@gmail.com",
                account_email: "nicolas1@juliedesk.com"
            },
            {
                email: "juju@gmail.com",
                account_email: "juju@juliedesk.com"
            }
        ].to_json
        @message_classification_1 = FactoryGirl.create(:message_classification, message: message_1, attendees: attendees_1)
        @messages_thread_2 = FactoryGirl.create(:messages_thread, account_email: "nicolas3@juliedesk.com")
      end

      it "should migrate all" do
        Account.migrate_account_email "nicolas1@juliedesk.com", "nicolas2@juliedesk.com"
        expect(MessagesThread.find(@messages_thread_1.id).account_email).to eq("nicolas4@juliedesk.com")
        expect(MessageClassification.find(@message_classification_1.id).attendees).to eq([
        {
            email: "julien@juliedesk.com"
        },
        {
            email: "nicolas@gmail.com",
            account_email: "nicolas2@juliedesk.com"
        },
        {
            email: "juju@gmail.com",
            account_email: "juju@juliedesk.com"
        }
                                                                                                          ].to_json)
        expect(MessagesThread.find(@messages_thread_2.id).account_email).to eq("nicolas3@juliedesk.com")
      end
    end

    context "simple context - with constraints to update" do
      before do
        @messages_thread_1 = FactoryGirl.create(:messages_thread, account_email: "nicolas1@juliedesk.com")
        message_1 = FactoryGirl.create(:message, messages_thread: @messages_thread_1)
        attendees_1 = [
            {
                email: "julien@juliedesk.com"
        },
            {
                email: "nicolas@gmail.com",
            account_email: "nicolas1@juliedesk.com"
        },
            {
                email: "juju@gmail.com",
            account_email: "juju@juliedesk.com"
        }
        ].to_json

        constraints_1 = [
            {
                attendee_email: "nicolas1@juliedesk.com",
                data: "Lorem"
            },
            {
                attendee_email: "juju@gmail.com",
                data: "Lorem"
            }
        ].to_json
        @message_classification_1 = FactoryGirl.create(:message_classification, message: message_1, attendees: attendees_1, constraints_data: constraints_1)
        attendees_2 = [
        {
            email: "julien@juliedesk.com"
        },
        {
            email: "nicolas1@juliedesk.com",
            account_email: "nicolas1@juliedesk.com"
        },
        {
            email: "juju@gmail.com",
            account_email: "juju@juliedesk.com"
        }
        ].to_json

        constraints_2 = [
        {
            attendee_email: "nicolas1@juliedesk.com",
            data: "Lorem"
        },
        {
            attendee_email: "juju@gmail.com",
            data: "Lorem"
        }
        ].to_json
        @messages_thread_2 = FactoryGirl.create(:messages_thread, account_email: "nicolas3@juliedesk.com")
        message_2 = FactoryGirl.create(:message, messages_thread: @messages_thread_2)
        @message_classification_2 = FactoryGirl.create(:message_classification, message: message_2, attendees: attendees_2, constraints_data: constraints_2)
      end

      it "should migrate all" do
        Account.migrate_account_email "nicolas1@juliedesk.com", "nicolas2@juliedesk.com"
        expect(MessagesThread.find(@messages_thread_1.id).account_email).to eq("nicolas2@juliedesk.com")
        expect(MessageClassification.find(@message_classification_1.id).attendees).to eq([
                                                                                             {
                                                                                                 email: "julien@juliedesk.com"
        },
            {
                email: "nicolas@gmail.com",
            account_email: "nicolas2@juliedesk.com"
        },
            {
                email: "juju@gmail.com",
            account_email: "juju@juliedesk.com"
        }
        ].to_json)
        expect(MessageClassification.find(@message_classification_1.id).constraints_data).to eq(
        [
           {
            attendee_email: "nicolas2@juliedesk.com",
            data: "Lorem"
           },
           {
            attendee_email: "juju@gmail.com",
            data: "Lorem"
           }
        ].to_json)

        expect(MessagesThread.find(@messages_thread_2.id).account_email).to eq("nicolas3@juliedesk.com")

        expect(MessageClassification.find(@message_classification_2.id).attendees).to eq([
         {
             email: "julien@juliedesk.com"
         },
         {
             email: "nicolas1@juliedesk.com",
             account_email: "nicolas2@juliedesk.com"
         },
         {
             email: "juju@gmail.com",
             account_email: "juju@juliedesk.com"
        }
        ].to_json)
        expect(MessageClassification.find(@message_classification_2.id).constraints_data).to eq(
        [
        {
            attendee_email: "nicolas1@juliedesk.com",
            data: "Lorem"
        },
        {
            attendee_email: "juju@gmail.com",
            data: "Lorem"
        }
        ].to_json)
      end
    end
  end

  describe 'is_in_circle_of_trust?' do
    let(:accounts_cache) {
      {
        'client@email.com' => {
          'circle_of_trust' => {
            'trusting_everyone' => false,
            'trusted_domains' =>
              [
                  'domain1.com',
                  'domain2.com'
              ],
            'trusted_emails' =>
              [
                  'email1@email.com',
                  'email2@email.com'
              ]
          }
        }
      }
    }

    let(:account) { Account.create_from_email('client@email.com') }

    before(:example) do
      allow(Account).to receive(:accounts_cache_for_email).and_return(accounts_cache['client@email.com'])
    end

    context 'from emails' do
      it 'should return true' do
        expect(account.is_in_circle_of_trust?('email1@email.com')).to be(true)
      end
    end

    context 'from domains' do
      it 'should return true' do
        expect(account.is_in_circle_of_trust?('email3@domain1.com')).to be(true)
      end
    end

    it 'should return false' do
      expect(account.is_in_circle_of_trust?('email3@email.com')).to be(false)
    end
  end
end