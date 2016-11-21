FactoryGirl.define do
  sequence :account_email do |n|
    "email#{n}@test.com"
  end

  factory :messages_thread do

    transient do
      messages_count 1
    end

    factory :messages_thread_with_messages do
      after(:create) do |messages_thread, evaluator|
        create_list(:message_complete,  evaluator.messages_count, messages_thread: messages_thread)
      end
    end

    factory :messages_thread_for_inbox_count do
      account_email

      trait :is_sent_to_admin do
        sent_to_admin true
      end

      trait :in_in_inbox do
        in_inbox true
      end

      factory :messages_thread_for_inbox_count_in_inbox, traits: [:in_in_inbox]
      factory :messages_thread_for_inbox_count_sent_to_admin_in_inbox, traits: [:is_sent_to_admin, :in_in_inbox]
      factory :messages_thread_for_inbox_count_sent_to_admin_not_in_inbox, traits: [:is_sent_to_admin]

    end

  end
end