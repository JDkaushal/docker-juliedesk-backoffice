FactoryGirl.define do
  factory :message do
    received_at Time.now

    factory :message_complete do
      after(:create) do |message|
        create(:message_classification_complete, message: message)
      end
    end

    factory :message_with_interpretations do
      after(:create) do |message|
        create(:main_classification, message: message)
      end
    end
  end
end