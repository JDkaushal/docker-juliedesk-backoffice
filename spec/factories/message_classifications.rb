FactoryGirl.define do
  factory :message_classification do

    factory :message_classification_complete do
      after(:create) do |message_classification|
        create(:julie_action, message_classification: message_classification)
      end
    end
  end
end