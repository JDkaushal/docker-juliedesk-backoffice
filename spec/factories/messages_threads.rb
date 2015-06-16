FactoryGirl.define do
  factory :messages_thread do

    transient do
      messages_count 1
    end

    factory :messages_thread_with_messages do
      after(:create) do |messages_thread, evaluator|
        create_list(:message_complete,  evaluator.messages_count, messages_thread: messages_thread)
      end
    end
  end
end