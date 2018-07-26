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


  describe '#previous_classification' do
    let(:messages_thread) { create(:messages_thread) }
    let(:current_message_classification_params) { { } }
    let(:current_message_classification) { create(:message_classification, { classification: MessageClassification::ASK_AVAILABILITIES }.merge(current_message_classification_params)) }

    subject { current_message_classification.previous_classification }

    context 'when no previous classification' do
      let!(:first_message)    { create(:message, messages_thread: messages_thread) }
      let!(:current_message)  { create(:message, messages_thread: messages_thread) }
      let(:current_message_classification_params) { { message: current_message }}

      it { is_expected.to be_nil}
    end

    context 'when previous message has a classification' do
      let!(:first_message) { create(:message, messages_thread: messages_thread, received_at: Time.now) }
      let!(:existing_classification) { create(:message_classification, classification: MessageClassification::ASK_DATE_SUGGESTIONS, message: first_message) }

      let!(:current_message)  { create(:message, messages_thread: messages_thread, received_at: Time.now) }
      let(:current_message_classification_params) { { message: current_message }}

      it { is_expected.to eq(existing_classification) }
    end


    context 'when previous message has multiple classifications' do
      let!(:first_message)           { create(:message, messages_thread: messages_thread, received_at: Time.now) }
      let!(:existing_classification) { create(:message_classification, classification: MessageClassification::ASK_DATE_SUGGESTIONS, message: first_message) }
      let!(:latest_classification)   { create(:message_classification, classification: MessageClassification::ASK_DATE_SUGGESTIONS, message: first_message) }

      let!(:current_message)  { create(:message, messages_thread: messages_thread, received_at: Time.now) }
      let(:current_message_classification_params) { { message: current_message }}

      it { is_expected.to eq(latest_classification) }
    end


    context 'when both messages have classifications' do
      let!(:first_message)           { create(:message, messages_thread: messages_thread, received_at: Time.now) }
      let!(:existing_classification) { create(:message_classification, classification: MessageClassification::ASK_DATE_SUGGESTIONS, message: first_message) }
      let!(:latest_classification)   { create(:message_classification, classification: MessageClassification::ASK_DATE_SUGGESTIONS, message: first_message) }

      let!(:current_message)  { create(:message, messages_thread: messages_thread, received_at: Time.now) }
      let!(:current_message_existing_classification)   { create(:message_classification, classification: MessageClassification::ASK_AVAILABILITIES, message: current_message) }
      let(:current_message_classification_params) { { message: current_message }}

      it { is_expected.to eq(latest_classification) }
    end

  end
end