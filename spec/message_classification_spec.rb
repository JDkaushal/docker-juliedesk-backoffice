require "rails_helper"

describe MessageClassification, :type => :model do

  before do

  end

  describe "clean_and_categorize_clients" do
    before do
      expect(Account).to receive(:get_active_account_emails).with(detailed: true).and_return([
          {
              'email' => "nicolas@wepopp.com",
              'email_aliases' => [],
              'usage_name' => "Nicolas Marlier"
          },
          {
              'email' => "nmarlier@gmail.com",
              'email_aliases' => ["elrandil@gmail.com"],
              'usage_name' => "Elrandil"
          }
      ])
    end
    it "Should clean and categorize attendees" do
      response = MessageClassification.clean_and_categorize_clients([
                                                             {
                                                                 'email' => "nicolas@wepopp.com",
                                                                 'usage_name' => ""
                                                             },
                                                             {
                                                                 'email' => "elrandil@gmail.com",
                                                                 'usage_name' => ""
                                                             },
                                                             {
                                                                 'email' => " julien@wepopp.com",
                                                                 'usage_name' => "Julien Hobeika"
                                                             }
                                                         ])
      expect(response).to eq([
                                 {
                                     'email' => "nicolas@wepopp.com",
                                     'account_email' => "nicolas@wepopp.com",
                                     'usage_name' => "Nicolas Marlier"
                                 },
                                 {
                                     'email' => "elrandil@gmail.com",
                                     'account_email' => "nmarlier@gmail.com",
                                     'usage_name' => "Elrandil"
                                 },
                                 {
                                     'email' => "julien@wepopp.com",
                                     'usage_name' => "Julien Hobeika"
                                 }
                             ])
    end
  end

end