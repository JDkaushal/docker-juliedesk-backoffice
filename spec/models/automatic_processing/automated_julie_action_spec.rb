require "rails_helper"
require_relative './mocking_helpers/attendees'

describe AutomaticProcessing::AutomatedJulieAction do
  let(:account_email) { 'stagingjuliedesk@gmail.com' }
  let(:parsed_user_cache) {
    {
        "email"=>"stagingjuliedesk@gmail.com",
        "state"=>"active_state",
        "subscribed"=>true,
        "configured"=>true,
        "company_hash"=>{
            "name"=>"Julie Desk",
            "identifier"=>"team-83dcefb7",
            "timezone"=>"Europe/Paris",
            "working_hours"=>{
                "mon"=>{
                    "0"=>[0, 2400]
                },
                "tue"=>{
                    "0"=>[0, 2400]
                },
                "wed"=>{
                    "0"=>[0, 2400]
                },
                "thu"=>{
                    "0"=>[0, 2400]
                },
                "fri"=>{
                    "0"=>[0, 2400]
                },
                "sat"=>{
                    "0"=>[0, 2400]
                },
                "sun"=>{
                    "0"=>[0, 2400]
                }
            },
            "meeting_rooms_prioritization_rules"=>nil
        },
        "usage_name"=>"Fred",
        "first_name"=>"Fred",
        "last_name"=>"Grais",
        "full_name"=>"Fred Grais",
        "default_timezone_id"=>"Europe/Paris",
        "email_aliases"=>["frederic@juliedesk.com"],
        "office_365_refresh_token_expired"=>false,
        "is_pro"=>false,
        "created_at"=>"2018-02-12 13:05:08 UTC",
        "id"=>4,
        "only_admin_can_process"=>false,
        "only_support_can_process"=>false,
        "have_priority"=>false,
        "block_until_preferences_change"=>false,
        "last_sync_date"=>nil,
        "unbooking_hours"=>{
            "mon"=>[
                [0, 900],
                [1800, 2400]
            ],
            "tue"=>[
                [0, 900], [1800, 2400]
            ],
            "wed"=>[
                [0, 900], [1800, 2400]
            ],
            "thu"=>[
                [0, 900], [1800, 2400]
            ],
            "fri"=>[
                [0, 900], [1800, 2400]
            ],
            "sat"=>[
                [0, 2400]
            ],
            "sun"=>[
                [0, 2400]
            ]
        },
        "temporary_unavailabilities"=>[],
        "calendars_to_show"=>{
            "stagingjuliedesk@gmail.com"=>["1"]
        },
        "calendar_to_add"=>{
            "stagingjuliedesk@gmail.com"=>"1"
        },
        "calendar_logins"=>[
            {
                "username"=>"stagingjuliedesk@gmail.com",
                "type"=>"GoogleLogin",
                "rule"=>"EMAIL_ALIAS=XXX",
                "is_calendar_sharing"=>false,
                "lost_access_details"=>nil
            }
        ],
        "delay_between_appointments"=>0,
        "default_commuting_time"=>30,
        "default_appointments"=>[],
        "appointments"=>[
            {
                "address_type"=>nil,
                "kind"=>"dinner",
                "support_config_type"=>"",
                "duration"=>90,
                "type"=>nil,
                "number_in_location"=>false,
                "custom_location"=>nil,
                "custom_notes"=>nil,
                "include_email_in_notes"=>true,
                "default_number_to_call"=>nil,
                "support_config_id"=>nil,
                "behaviour"=>nil,
                "required_additional_informations"=>"mobile_only",
                "meeting_room_used"=>false,
                "selected_meeting_room"=>"auto_room_selection|attendees_count",
                "address_id"=>nil,
                "label"=>"dinner",
                "note"=>{
                    "fr"=>"",
                    "en"=>""
                },
                "title_in_calendar"=>{
                    "en"=>"Dinner",
                    "fr"=>"Dîner"
                },
                "title_in_email"=>{
                    "en"=>"dinner appointment",
                    "fr"=>"un dîner"
                },
                "designation_in_email"=>{
                    "en"=>"the dinner appointment",
                    "fr"=>"le dîner"
                },
                "addresses_with_description"=>[
                    {
                        "label"=>"A choisir par l'interlocuteur",
                        "address"=>"",
                        "type"=>nil,
                        "address_complement"=>"",
                        "address_in_template"=>{
                            "fr"=>"",
                            "en"=>"",
                            "en-US"=>"",
                            "en-GB"=>""
                        }
                    },
                    {
                        "label"=>"Le client choisira plus tard",
                        "address"=>"",
                        "type"=>nil,
                        "address_complement"=>"",
                        "address_in_template"=>{
                            "fr"=>"",
                            "en"=>"",
                            "en-US"=>"",
                            "en-GB"=>""}
                    },
                    {
                        "label"=>"Le client choisira plus tard",
                        "address"=>"",
                        "type"=>nil,
                        "address_complement"=>"",
                        "address_in_template"=>{
                            "fr"=>"",
                            "en"=>"",
                            "en-US"=>"",
                            "en-GB"=>""}
                    },
                    {
                        "label"=>"A choisir par l'interlocuteur",
                        "address"=>"",
                        "type"=>nil,
                        "address_complement"=>"",
                        "address_in_template"=>{
                            "fr"=>"",
                            "en"=>"",
                            "en-US"=>"",
                            "en-GB"=>""}
                    },
                    {
                        "label"=>"hythtyh",
                        "address"=>"",
                        "type"=>nil,
                        "address_complement"=>"",
                        "address_in_template"=>{
                            "fr"=>"",
                            "en"=>"",
                            "en-US"=>"",
                            "en-GB"=>""}
                    },
                    {
                        "label"=>"Bureau",
                        "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France",
                        "type"=>nil,
                        "address_complement"=>"",
                        "address_in_template"=>{
                            "fr"=>"",
                            "en"=>"",
                            "en-US"=>"",
                            "en-GB"=>""
                        }
                    }
                ],
                "needs_address"=>true,
                "default_address"=>nil,
                "number_to_call"=>nil,
                "appointment_kind_hash"=>{
                    "is_virtual"=>false,
                    "family_kind"=>"dinner",
                    "rule"=>""
                },
                "support_config_hash"=>{
                    "label"=>"dinner",
                    "mobile_in_note"=>true,
                    "landline_in_note"=>false,
                    "confcall_in_note"=>false,
                    "skype_in_note"=>false,
                    "rescue_with_mobile"=>false,
                    "rescue_with_landline"=>false,
                    "rescue_with_confcall"=>false,
                    "rescue_with_skype"=>false
                },
                "designation"=>"dinner"
            },
            {
                "address_type"=>nil,
                "kind"=>"breakfast",
                "support_config_type"=>"",
                "duration"=>60,
                "type"=>nil,
                "number_in_location"=>false,
                "custom_location"=>nil,
                "custom_notes"=>nil,
                "include_email_in_notes"=>true,
                "default_number_to_call"=>nil,
                "support_config_id"=>nil,
                "behaviour"=>nil,
                "required_additional_informations"=>"mobile_only",
                "meeting_room_used"=>false,
                "selected_meeting_room"=>"",
                "address_id"=>nil,
                "label"=>"breakfast",
                "note"=>{
                    "fr"=>"",
                    "en"=>""
                },
                "title_in_calendar"=>{
                    "en"=>"Breakfast",
                    "fr"=>"Petit-déjeuner"
                },
                "title_in_email"=>{
                    "en"=>"breakfast",
                    "fr"=>"un petit-déjeuner"
                },
                "designation_in_email"=>{
                    "en"=>"the breakfast",
                    "fr"=>"le petit-déjeuner"
                },
                "addresses_with_description"=>[
                    {"label"=>"A choisir par l'interlocuteur",
                     "address"=>"",
                     "type"=>nil,
                     "address_complement"=>"",
                     "address_in_template"=>{
                         "fr"=>"",
                         "en"=>"",
                         "en-US"=>"",
                         "en-GB"=>""}
                    },
                    {
                        "label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>true, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>false, "family_kind"=>"breakfast", "rule"=>""}, "support_config_hash"=>{"label"=>"breakfast", "mobile_in_note"=>true, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"breakfast"}, {"address_type"=>nil, "kind"=>"hangout", "support_config_type"=>"", "duration"=>30, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>"", "include_email_in_notes"=>true, "default_number_to_call"=>nil, "support_config_id"=>0, "behaviour"=>"later", "required_additional_informations"=>"empty", "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_id"=>nil, "label"=>"hangout", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Google Hangout", "fr"=>"Google Hangout"}, "title_in_email"=>{"en"=>"a Google Hangout", "fr"=>"un Google Hangout"}, "designation_in_email"=>{"en"=>"the Google Hangout", "fr"=>"le Google Hangout"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>false, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>true, "family_kind"=>"hangout", "rule"=>""}, "support_config_hash"=>{"label"=>"hangout", "mobile_in_note"=>false, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"hangout"}, {"address_type"=>nil, "kind"=>"coffee", "support_config_type"=>"", "duration"=>60, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>nil, "include_email_in_notes"=>true, "default_number_to_call"=>nil, "support_config_id"=>nil, "behaviour"=>nil, "required_additional_informations"=>"mobile_only", "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_id"=>nil, "label"=>"coffee", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Coffee", "fr"=>"Café"}, "title_in_email"=>{"en"=>"a coffee", "fr"=>"prendre un café"}, "designation_in_email"=>{"en"=>"the coffee", "fr"=>"le café"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>true, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>false, "family_kind"=>"coffee", "rule"=>""}, "support_config_hash"=>{"label"=>"coffee", "mobile_in_note"=>true, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"coffee"}, {"address_type"=>nil, "kind"=>"confcall", "support_config_type"=>"VirtualAppointmentSupportConfig", "support_config_id"=>30, "duration"=>30, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>"", "include_email_in_notes"=>true, "default_number_to_call"=>nil, "behaviour"=>"propose", "required_additional_informations"=>"empty", "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_id"=>nil, "label"=>"confcall", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Call", "fr"=>"Call"}, "title_in_email"=>{"en"=>"a call", "fr"=>"un rendez-vous téléphonique"}, "designation_in_email"=>{"en"=>"the call", "fr"=>"le rendez-vous téléphonique"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>false, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>true, "family_kind"=>"call", "rule"=>"ATTENDEES>1"}, "support_config_hash"=>{"label"=>"Confcall", "mobile_in_note"=>true, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>true, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"confcall"}, {"address_type"=>nil, "kind"=>"drink", "support_config_type"=>"", "duration"=>60, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>nil, "include_email_in_notes"=>true, "default_number_to_call"=>nil, "support_config_id"=>nil, "behaviour"=>nil, "required_additional_informations"=>"mobile_only", "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_id"=>nil, "label"=>"drink", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Drink", "fr"=>"Verre"}, "title_in_email"=>{"en"=>"a drink appointment", "fr"=>"prendre un verre"}, "designation_in_email"=>{"en"=>"the drink appointment", "fr"=>"le verre"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>true, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>false, "family_kind"=>"drink", "rule"=>""}, "support_config_hash"=>{"label"=>"drink", "mobile_in_note"=>true, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"drink"}, {"address_type"=>nil, "kind"=>"webex", "support_config_type"=>"", "duration"=>30, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>"", "include_email_in_notes"=>true, "default_number_to_call"=>nil, "support_config_id"=>0, "behaviour"=>"later", "required_additional_informations"=>"empty", "meeting_room_used"=>false, "selected_meeting_room"=>"auto_room_selection|attendees_count", "address_id"=>nil, "label"=>"webex", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"WebEx", "fr"=>"WebEx"}, "title_in_email"=>{"en"=>"an online meeting", "fr"=>"une présentation web"}, "designation_in_email"=>{"en"=>"the online meeting", "fr"=>"la présentation web"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>false, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>true, "family_kind"=>"webex", "rule"=>""}, "support_config_hash"=>{"label"=>"webex", "mobile_in_note"=>false, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"webex"}, {"address_type"=>nil, "kind"=>"lunch", "support_config_type"=>"", "duration"=>90, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>nil, "include_email_in_notes"=>true, "default_number_to_call"=>nil, "support_config_id"=>nil, "behaviour"=>nil, "required_additional_informations"=>"mobile_only", "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_id"=>nil, "label"=>"lunch", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Lunch", "fr"=>"Dej"}, "title_in_email"=>{"en"=>"lunch", "fr"=>"un déjeuner"}, "designation_in_email"=>{"en"=>"the lunch", "fr"=>"le déjeuner"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>true, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>false, "family_kind"=>"lunch", "rule"=>""}, "support_config_hash"=>{"label"=>"lunch", "mobile_in_note"=>true, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"lunch"}, {"address_type"=>"UserTeamAddress", "address_id"=>4, "kind"=>"meeting", "support_config_type"=>"", "duration"=>60, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>nil, "include_email_in_notes"=>true, "default_number_to_call"=>nil, "support_config_id"=>nil, "behaviour"=>nil, "required_additional_informations"=>"mobile_only", "meeting_room_used"=>false, "selected_meeting_room"=>"auto_room_selection|attendees_count", "label"=>"meeting", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Mtg", "fr"=>"Réunion"}, "title_in_email"=>{"en"=>"a meeting", "fr"=>"une réunion"}, "designation_in_email"=>{"en"=>"the meeting", "fr"=>"la réunion"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>true, "default_address"=>{"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>false, "family_kind"=>"meeting", "rule"=>""}, "support_config_hash"=>{"label"=>"meeting", "mobile_in_note"=>true, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"meeting"}, {"address_type"=>nil, "kind"=>"skype", "support_config_type"=>"VirtualAppointmentSupportConfig", "support_config_id"=>27, "duration"=>30, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>"", "include_email_in_notes"=>true, "default_number_to_call"=>nil, "behaviour"=>"propose", "required_additional_informations"=>"skype_only", "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_id"=>nil, "label"=>"skype", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Skype", "fr"=>"Skype"}, "title_in_email"=>{"en"=>"a Skype appointment", "fr"=>"un Skype"}, "designation_in_email"=>{"en"=>"the Skype appointment", "fr"=>"le Skype"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>false, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>true, "family_kind"=>"skype", "rule"=>""}, "support_config_hash"=>{"label"=>"Skype", "mobile_in_note"=>false, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>true, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"skype"}, {"address_type"=>nil, "kind"=>"visio", "support_config_type"=>"VirtualAppointmentSupportConfig", "support_config_id"=>30, "duration"=>30, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>"", "include_email_in_notes"=>true, "default_number_to_call"=>nil, "behaviour"=>"propose", "required_additional_informations"=>"empty", "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_id"=>nil, "label"=>"visio", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Video conference", "fr"=>"Vidéo conférence"}, "title_in_email"=>{"en"=>"a video conference", "fr"=>"une vidéo conférence"}, "designation_in_email"=>{"en"=>"the video conference", "fr"=>"la vidéo conférence"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>false, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>true, "family_kind"=>"visio", "rule"=>""}, "support_config_hash"=>{"label"=>"Confcall", "mobile_in_note"=>true, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>true, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"video conference"}, {"address_type"=>"UserTeamAddress", "address_id"=>4, "kind"=>"work_session", "support_config_type"=>"", "duration"=>60, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>nil, "include_email_in_notes"=>true, "default_number_to_call"=>nil, "support_config_id"=>nil, "behaviour"=>nil, "required_additional_informations"=>"mobile_only", "meeting_room_used"=>false, "selected_meeting_room"=>"auto_room_selection|attendees_count", "label"=>"work_session", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Work Session", "fr"=>"Session de travail"}, "title_in_email"=>{"en"=>"a working session", "fr"=>"une session de travail"}, "designation_in_email"=>{"en"=>"the working session", "fr"=>"la session de travail"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>true, "default_address"=>{"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>false, "family_kind"=>"work_session", "rule"=>""}, "support_config_hash"=>{"label"=>"work_session", "mobile_in_note"=>false, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"work_session"}, {"address_type"=>"UserTeamAddress", "address_id"=>4, "kind"=>"appointment", "support_config_type"=>"", "duration"=>60, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>nil, "include_email_in_notes"=>true, "default_number_to_call"=>nil, "support_config_id"=>nil, "behaviour"=>nil, "required_additional_informations"=>"mobile_only", "meeting_room_used"=>true, "selected_meeting_room"=>"auto_room_selection|attendees_count", "label"=>"appointment", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Mtg", "fr"=>"RDV"}, "title_in_email"=>{"en"=>"a meeting", "fr"=>"un rendez-vous"}, "designation_in_email"=>{"en"=>"the meeting", "fr"=>"le rendez-vous"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>true, "default_address"=>{"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>false, "family_kind"=>"appointment", "rule"=>""}, "support_config_hash"=>{"label"=>"appointment", "mobile_in_note"=>true, "landline_in_note"=>false, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"appointment"}, {"address_type"=>nil, "kind"=>"call", "support_config_type"=>"VirtualAppointmentSupportConfig", "support_config_id"=>29, "duration"=>30, "type"=>nil, "number_in_location"=>false, "custom_location"=>nil, "custom_notes"=>"", "include_email_in_notes"=>true, "default_number_to_call"=>nil, "behaviour"=>"ask_interlocutor", "required_additional_informations"=>"empty", "meeting_room_used"=>true, "selected_meeting_room"=>"auto_room_selection|attendees_count", "address_id"=>nil, "label"=>"call", "note"=>{"fr"=>"", "en"=>""}, "title_in_calendar"=>{"en"=>"Call", "fr"=>"Call"}, "title_in_email"=>{"en"=>"a call", "fr"=>"un rendez-vous téléphonique"}, "designation_in_email"=>{"en"=>"the call", "fr"=>"le rendez-vous téléphonique"}, "addresses_with_description"=>[{"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Le client choisira plus tard", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"A choisir par l'interlocuteur", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"hythtyh", "address"=>"", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}, {"label"=>"Bureau", "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "type"=>nil, "address_complement"=>"", "address_in_template"=>{"fr"=>"", "en"=>"", "en-US"=>"", "en-GB"=>""}}], "needs_address"=>false, "default_address"=>nil, "number_to_call"=>nil, "appointment_kind_hash"=>{"is_virtual"=>true, "family_kind"=>"call", "rule"=>"ATTENDEES<2"}, "support_config_hash"=>{"label"=>"Demander à l'interlocuteur", "mobile_in_note"=>true, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false}, "designation"=>"call"}], "addresses"=>[{"kind"=>"restaurant", "label"=>"A choisir par l'interlocuteur", "address"=>"", "address_complement"=>"", "type"=>nil, "meeting_rooms_enabled"=>false, "available_meeting_rooms"=>[], "is_main_address"=>false, "latitude"=>nil, "longitude"=>nil, "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_kind"=>{"label"=>"restaurant", "id"=>1, "is_defined"=>true, "created_at"=>"2015-04-16T16:20:15.279Z", "updated_at"=>"2015-04-16T16:20:15.279Z"}}, {"kind"=>"restaurant", "label"=>"Le client choisira plus tard", "address"=>"", "address_complement"=>"", "type"=>nil, "meeting_rooms_enabled"=>false, "available_meeting_rooms"=>[], "is_main_address"=>false, "latitude"=>nil, "longitude"=>nil, "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_kind"=>{"label"=>"restaurant", "id"=>1, "is_defined"=>true, "created_at"=>"2015-04-16T16:20:15.279Z", "updated_at"=>"2015-04-16T16:20:15.279Z"}}, {"kind"=>"client_will_define", "label"=>"Le client choisira plus tard", "address"=>"", "address_complement"=>"", "type"=>nil, "meeting_rooms_enabled"=>false, "available_meeting_rooms"=>[], "is_main_address"=>false, "latitude"=>nil, "longitude"=>nil, "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_kind"=>{"label"=>"client_will_define", "id"=>8, "is_defined"=>false, "created_at"=>"2015-04-16T16:20:15.317Z", "updated_at"=>"2015-04-16T16:20:44.849Z"}}, {"kind"=>"ask_interlocuter", "label"=>"A choisir par l'interlocuteur", "address"=>"", "address_complement"=>"", "type"=>nil, "meeting_rooms_enabled"=>false, "available_meeting_rooms"=>[], "is_main_address"=>false, "latitude"=>nil, "longitude"=>nil, "meeting_room_used"=>false, "selected_meeting_room"=>"auto_room_selection|attendees_count", "address_kind"=>{"label"=>"ask_interlocuter", "id"=>9, "is_defined"=>false, "created_at"=>"2015-04-16T16:20:15.323Z", "updated_at"=>"2015-04-16T16:20:44.856Z"}}, {"label"=>"hythtyh", "is_main_address"=>false, "address"=>"", "address_complement"=>"", "kind"=>"locations_cluster", "meeting_rooms_enabled"=>false, "available_meeting_rooms"=>[], "meeting_room_used"=>false, "selected_meeting_room"=>"", "address_kind"=>{"label"=>"locations_cluster", "id"=>13, "is_defined"=>true, "created_at"=>"2018-01-22T15:48:17.542Z", "updated_at"=>"2018-01-22T15:48:17.542Z"}, "latitude"=>nil, "longitude"=>nil, "child_team_addresses_ids"=>[], "team_address_id"=>4, "floor"=>nil}, {"label"=>"Bureau", "is_main_address"=>true, "address"=>"15bis Boulevard Saint-Denis, 75002 Paris, France", "address_complement"=>"", "kind"=>"office", "meeting_rooms_enabled"=>true, "available_meeting_rooms"=>[{"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>true, "can_visio"=>nil, "capacity"=>nil, "id"=>"email101@email.com", "summary"=>"Test101", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email100@email.com", "summary"=>"Test100", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email102@email.com", "summary"=>"Test102", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email103@email.com", "summary"=>"Test103", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email104@email.com", "summary"=>"Test104", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email105@email.com", "summary"=>"Test105", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email106@email.com", "summary"=>"Test106", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email0@email.com", "summary"=>"Test0", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email1@email.com", "summary"=>"Test1", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}, {"calendar_login_username"=>"ews_company_meeting_room", "can_confcall"=>nil, "can_visio"=>nil, "capacity"=>nil, "id"=>"email10@email.com", "summary"=>"Test10", "floor"=>nil, "in_main_location"=>true, "on_default_floor"=>true, "floor_location_score"=>1.0}], "meeting_room_used"=>true, "selected_meeting_room"=>"auto_room_selection|attendees_count", "address_kind"=>{"label"=>"office", "id"=>4, "is_defined"=>true, "created_at"=>"2015-04-16T16:20:15.296Z", "updated_at"=>"2015-04-16T16:20:15.296Z"}, "latitude"=>48.8693132, "longitude"=>2.3532911, "child_team_addresses_ids"=>[], "team_address_id"=>1, "floor"=>nil}], "virtual_appointments_support_config"=>[{"label"=>"Confcall", "mobile_in_note"=>true, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>true, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false, "video_conference_in_note"=>false, "rescue_with_video_conference"=>false}, {"label"=>"Demander à l'interlocuteur", "mobile_in_note"=>true, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false, "video_conference_in_note"=>false, "rescue_with_video_conference"=>false}, {"label"=>"Landline", "mobile_in_note"=>false, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false, "video_conference_in_note"=>false, "rescue_with_video_conference"=>false}, {"label"=>"Mobile", "mobile_in_note"=>true, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false, "video_conference_in_note"=>false, "rescue_with_video_conference"=>false}, {"label"=>"Skype", "mobile_in_note"=>false, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>true, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false, "video_conference_in_note"=>false, "rescue_with_video_conference"=>false}, {"label"=>"Skype for Business", "mobile_in_note"=>false, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>false, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false, "video_conference_in_note"=>false, "rescue_with_video_conference"=>false}, {"label"=>"Vide", "mobile_in_note"=>true, "landline_in_note"=>true, "confcall_in_note"=>true, "skype_in_note"=>true, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false, "video_conference_in_note"=>false, "rescue_with_video_conference"=>false}, {"label"=>"Video Conference", "mobile_in_note"=>true, "landline_in_note"=>true, "confcall_in_note"=>false, "skype_in_note"=>true, "rescue_with_mobile"=>false, "rescue_with_landline"=>false, "rescue_with_confcall"=>false, "rescue_with_skype"=>false, "video_conference_in_note"=>false, "rescue_with_video_conference"=>false}], "virtual_appointments_company_support_config"=>[], "max_number_of_appointments"=>100, "mobile_number"=>"", "landline_number"=>"", "confcall_instructions"=>"", "sfb_instructions"=>"$SKYPE_FOR_BUSINESS_MEETING_LINK_TO_BE_GENERATED$", "video_conference_instructions"=>"", "skype"=>"", "means_of_transport"=>"", "raw_preferences"=>"", "current_notes"=>"", "awaiting_current_notes"=>"", "locale"=>"en", "complaints_count"=>0, "title_preferences"=>{"general"=>"companies_and_names", "internal_meetings"=>"email_subject"}, "travel_time_transport_mode"=>"max", "language_level"=>"normal", "auto_follow_up_enabled"=>false, "restaurant_booking_enabled"=>false, "linked_attendees_enabled"=>false, "ignore_non_all_day_free_events"=>false, "julie_aliases"=>["julie@jdesk.onmicrosoft.com"], "using_calendar_server"=>true, "circle_of_trust"=>{"trusting_everyone"=>false, "trusted_domains"=>[], "trusted_emails"=>[]}, "lunch_time_preference"=>1230, "gender"=>"M", "auto_date_suggestions"=>false, "skype_for_business_meeting_generation_active"=>false, "preferred_meeting_rooms"=>[]}
  }
  let(:messages_thread) { FactoryGirl.create(:messages_thread, account_email: account_email) }
  let(:main_message_interpretation) { FactoryGirl.create(:main_classification, detected_classification: 'ask_availabilities') }
  let(:processed_message) { FactoryGirl.create(:message, messages_thread: messages_thread, main_message_interpretation: main_message_interpretation) }
  let(:message_classification) {
    AutomaticProcessing::AutomatedMessageClassification.process_message(processed_message, {})
  }

  subject(:julie_action) {
    AutomaticProcessing::AutomatedJulieAction.new(
        action_nature: message_classification.computed_julie_action_nature,
        message_classification: message_classification
    )
  }

  before(:each) do
    allow(Account).to receive(:accounts_cache_for_email).with(account_email).and_return(parsed_user_cache)
    allow(processed_message).to receive(:populate_single_server_message)

    MockingHelpers::Attendees.new.mock([
                                           {
                                               "guid"=>-1,
                                               "email"=>"threadOwner@owner.fr",
                                               "firstName"=>"Thread",
                                               "lastName"=>"Owner",
                                               "name"=>"Thread Owner",
                                               "usageName"=>"Thread",
                                               "gender"=>"M",
                                               "isAssistant"=>"false",
                                               "assisted"=>"false",
                                               "assistedBy"=>"",
                                               "company"=>"Owner Corp",
                                               "timezone"=>"Europe/Paris",
                                               "landline"=>"",
                                               "mobile"=>"+33102030405",
                                               "skypeId"=>"",
                                               "confCallInstructions"=>"",
                                               "status"=>"present",
                                               "isPresent"=>"true",
                                               "isClient"=>"true",
                                               "isThreadOwner"=>"true",
                                               "needAIConfirmation"=>"false",
                                               "aIHasBeenConfirmed"=>"true"
                                           },
                                           {
                                               "guid"=>"152418",
                                               "email"=>"john.bernard@grabou.fr",
                                               "firstName"=>"John",
                                               "lastName"=>"Bernard",
                                               "name"=>"John Bernard",
                                               "usageName"=>"John",
                                               "gender"=>"M",
                                               "isAssistant"=>"false",
                                               "assisted"=>"false",
                                               "assistedBy"=>"",
                                               "company"=>"Grabou Corp",
                                               "timezone"=>"Europe/Paris",
                                               "landline"=>"",
                                               "mobile"=>"+33102030405",
                                               "skypeId"=>"",
                                               "confCallInstructions"=>"",
                                               "status"=>"present",
                                               "isPresent"=>"true",
                                               "isClient"=>"false",
                                               "isThreadOwner"=>"false",
                                               "needAIConfirmation"=>"false",
                                               "aIHasBeenConfirmed"=>"true"
                                           },
                                           {
                                               "guid"=>"152418",
                                               "email"=>"babtou@fragile.fr",
                                               "firstName"=>"Babtou",
                                               "lastName"=>"Fragile",
                                               "name"=>"Babtou Fragile",
                                               "usageName"=>"Babtou",
                                               "gender"=>"M",
                                               "isAssistant"=>"false",
                                               "assisted"=>"false",
                                               "assistedBy"=>"",
                                               "company"=>"Babtou Corp",
                                               "timezone"=>"Europe/Paris",
                                               "landline"=>"",
                                               "mobile"=>"+33102030405",
                                               "skypeId"=>"",
                                               "confCallInstructions"=>"",
                                               "status"=>"present",
                                               "isPresent"=>"true",
                                               "isClient"=>"false",
                                               "isThreadOwner"=>"false",
                                               "needAIConfirmation"=>"false",
                                               "aIHasBeenConfirmed"=>"true"
                                           }
                                       ])
  end

  describe 'process' do

    context 'JD_ACTION_SUGGEST_DATES' do
      let(:main_message_interpretation) { FactoryGirl.create(:main_classification, detected_classification: 'ask_date_suggestions') }

      it 'should trigger the right actions' do
        expect(AutomaticProcessing::JulieActionsFlows::SuggestDates).to receive(:new).with(julie_action).and_call_original
        expect_any_instance_of(AutomaticProcessing::JulieActionsFlows::SuggestDates).to receive(:trigger)

        julie_action.process
      end
    end

    context 'JD_ACTION_CHECK_AVAILABILITIES' do
      let(:main_message_interpretation) { FactoryGirl.create(:main_classification, detected_classification: 'ask_availabilities') }

      it 'should trigger the right actions' do
        expect(AutomaticProcessing::JulieActionsFlows::CheckAvailabilities).to receive(:new).with(julie_action).and_call_original
        expect_any_instance_of(AutomaticProcessing::JulieActionsFlows::CheckAvailabilities).to receive(:trigger)

        julie_action.process
      end
    end

    context 'JD_ACTION_WAIT_FOR_CONTACT' do
      let(:main_message_interpretation) { FactoryGirl.create(:main_classification, detected_classification: 'wait_for_contact') }

      it 'should trigger the right actions' do
        expect(AutomaticProcessing::JulieActionsFlows::WaitForContact).to receive(:new).with(julie_action).and_call_original
        expect_any_instance_of(AutomaticProcessing::JulieActionsFlows::WaitForContact).to receive(:trigger)

        julie_action.process
      end
    end

    context 'JD_ACTION_SEND_CONFIRMATION' do
      let(:main_message_interpretation) { FactoryGirl.create(:main_classification, detected_classification: 'give_info') }

      it 'should trigger the right actions' do
        expect(AutomaticProcessing::JulieActionsFlows::SendConfirmation).to receive(:new).with(julie_action).and_call_original
        expect_any_instance_of(AutomaticProcessing::JulieActionsFlows::SendConfirmation).to receive(:trigger)

        julie_action.process
      end
    end
  end

  describe 'ask_ai_verify_dates' do

  end
end