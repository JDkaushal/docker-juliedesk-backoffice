FactoryGirl.define do
  factory :julie_action do

    trait :check_availabilities do
      #action_nature  JulieAction::JD_ACTION_CHECK_AVAILABILITIES
      action_nature "check_availabilities"
    end

    factory :check_availabilities_action, traits: [:check_availabilities]
  end
end