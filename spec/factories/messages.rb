FactoryGirl.define do
  factory :message do

    factory :message_complete do
      after(:create) do |message|
        create(:message_classification_complete, message: message)
      end
    end
  end
end