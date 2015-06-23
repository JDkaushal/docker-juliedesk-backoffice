require "rails_helper"

describe Account do

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
end