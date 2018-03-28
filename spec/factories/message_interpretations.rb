FactoryGirl.define do
  factory :message_interpretation do
    error false
    raw_response "{\"language_detected\": \"en\", \"location_confidence\": null, \"request_confidence\": 0.97, \"request_proba\": 0.98, \"request_model_date\": \"Mon Aug  7 13:28:19 2017\", \"asap\": false, \"email_id\": 1474749, \"contacts_infos\": [{\"owner\": \"owner@email.com\", \"text\": \"+49 15780928762\", \"tag\": \"PHONE\", \"value\": \"\"}], \"location_data\": null, \"formal_language\": false, \"request_classif\": \"ask_availabilities\", \"appointment_classif\": \"appointment\", \"constraints_data\": [{\"constraint_when_nature\": \"custom\", \"dates\": [\"2018-03-23\"], \"text\": \"\", \"start_time\": \"\", \"end_time\": \"\", \"constraint_nature\": \"can\", \"timezone\": \"Europe/Berlin\", \"attendee_email\": \"owner@email.com\"}], \"appointment_confidence\": 0.96, \"client_on_trip\": null, \"appointment_model_date\": \"Tue Aug  8 09:19:04 2017\", \"algo_duration\": 0, \"duration\": null, \"dates_to_check_confidence\": 0.98, \"dates_to_check\": [\"2018-03-23T16:00:00+01:00\"], \"appointment_proba\": 0.91}"

    trait :main_classif do
      transient do
        detected_classification 'ask_availabilities'
      end

      question 'main'

      before(:create) do |message_interpretation, evaluator|
        parsed_raw_response = JSON.parse(message_interpretation.raw_response)
        parsed_raw_response['request_classif'] = evaluator.detected_classification

        message_interpretation.raw_response = parsed_raw_response.to_json
      end
    end

    factory :main_classification, traits: [:main_classif]
  end
end