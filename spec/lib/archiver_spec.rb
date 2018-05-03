require "rails_helper"

describe Archiver do

  describe "messages_thread_ids_to_archive" do
    before do
      @mt1 = FactoryGirl.create(:messages_thread_with_messages, {messages_count: 1})
      @mt1.messages.first.update(received_at: DateTime.now - 8.months)
      @mt2 = FactoryGirl.create(:messages_thread_with_messages, {messages_count: 1})
      @mt2.messages.first.update(received_at: DateTime.now - 4.months)
      @mt3 = FactoryGirl.create(:messages_thread_with_messages, {messages_count: 2})
      ms = @mt3.messages
      ms[0].update(received_at: DateTime.now - 4.months)
      ms[1].update(received_at: DateTime.now - 8.months)

      @mt4 = FactoryGirl.create(:messages_thread)
    end

    it "should returns all messages_threads_ids with messages all received more than 6 months ago" do
      expect(Archiver.messages_thread_ids_to_archive.sort).to eq([@mt1.id, @mt4.id].sort)
    end
  end



  describe "archive_messages_thread", use_archive_db: true do
    before do
      @mt1 = FactoryGirl.create(:messages_thread_with_messages, {messages_count: 2})
      @mt2 = FactoryGirl.create(:messages_thread_with_messages, {messages_count: 2})
    end

    it "should archive this messages_thread" do
      Archiver.archive_messages_thread(@mt1.id)

      expect(MessagesThread.count).to eq(1)
      expect(MessagesThread.first.id).to eq(@mt2.id)
      expect(Message.count).to eq(2)
      expect(Message.all.map(&:id).sort).to eq(@mt2.messages.map(&:id).sort)


      current_conf = ActiveRecord::Base.connection_config
      begin

        ActiveRecord::Base.establish_connection(Rails.configuration.database_configuration["archive_test"])
        expect(MessagesThread.count).to eq(1)
        expect(MessagesThread.first.id).to eq(@mt1.id)
        expect(Message.count).to eq(2)
        expect(Message.all.map(&:id).sort).to eq(@mt1.messages.map(&:id).sort)
      ensure
        ActiveRecord::Base.establish_connection current_conf
      end



    end
  end
end