FactoryGirl.define do

  factory :event_title_review do

    trait :status_nil do
      status nil
    end

    trait :status_not_nil do
      status 'not nil'
    end

    factory :event_title_review_status_nil, traits: [:status_nil]
    factory :event_title_review_status_not_nil, traits: [:status_not_nil]
  end
end