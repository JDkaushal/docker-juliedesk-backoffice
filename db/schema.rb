# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171009084904) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_stat_statements"

  create_table "ai_email_flow_forecasts", force: true do |t|
    t.datetime "datetime"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "auto_message_classification_reviews", force: true do |t|
    t.integer  "auto_message_classification_id"
    t.integer  "operator_id"
    t.integer  "notation"
    t.text     "comments"
    t.text     "tags"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "resolved",                       default: false
  end

  create_table "auto_message_classifications", force: true do |t|
    t.string   "classification"
    t.integer  "message_id"
    t.string   "operator"
    t.boolean  "validated",                  default: false
    t.string   "appointment_nature"
    t.text     "summary"
    t.integer  "duration"
    t.text     "location"
    t.text     "attendees",                  default: "[]"
    t.text     "notes"
    t.text     "constraints"
    t.text     "date_times",                 default: "[]"
    t.string   "locale"
    t.string   "timezone"
    t.integer  "processed_in"
    t.string   "location_nature"
    t.boolean  "private",                    default: false
    t.text     "other_notes"
    t.text     "constraints_data",           default: "[]"
    t.boolean  "client_agreement",           default: false
    t.boolean  "attendees_are_noticed",      default: false
    t.text     "number_to_call"
    t.string   "review_status"
    t.text     "call_instructions",          default: "[]"
    t.string   "thread_status"
    t.text     "follow_up_data"
    t.string   "title_preference"
    t.json     "location_coordinates",       default: []
    t.boolean  "using_meeting_room",         default: false
    t.json     "meeting_room_details"
    t.boolean  "using_restaurant_booking",   default: false
    t.json     "restaurant_booking_details"
    t.boolean  "location_changed"
    t.json     "virtual_resource_used"
    t.json     "before_update_data"
    t.boolean  "from_ai",                    default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "batch_identifier"
    t.text     "annotated_reply"
    t.string   "language_level"
    t.boolean  "asap_constraint",            default: false
    t.json     "client_on_trip"
  end

  create_table "client_contacts", force: true do |t|
    t.string   "client_email",                           null: false
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "usage_name"
    t.string   "gender"
    t.boolean  "is_assistant"
    t.boolean  "assisted"
    t.string   "assisted_by"
    t.string   "company"
    t.string   "timezone"
    t.string   "landline"
    t.string   "mobile"
    t.string   "skypeId"
    t.text     "conf_call_instructions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "need_ai_confirmation",   default: false
    t.boolean  "ai_has_been_confirmed",  default: false
  end

  add_index "client_contacts", ["client_email", "email"], name: "index_client_contacts_on_client_email_and_email", unique: true, using: :btree

  create_table "company_domain_associations", force: true do |t|
    t.string   "company_name"
    t.string   "domain"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_editable",  default: true
  end

  add_index "company_domain_associations", ["company_name", "domain"], name: "index_company_domain_associations_on_company_name_and_domain", unique: true, using: :btree

  create_table "date_suggestions_comparison_reviews", force: true do |t|
    t.integer  "julie_action_id"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "date_suggestions_comparison_reviews", ["julie_action_id"], name: "index_date_suggestions_comparison_reviews_on_julie_action_id", using: :btree

  create_table "date_suggestions_reviews", force: true do |t|
    t.integer  "julie_action_id"
    t.boolean  "generated_from_julie_action"
    t.datetime "action_at"
    t.json     "date_suggestions"
    t.string   "review_set_status"
    t.json     "review_set_errors"
    t.integer  "review_items_incorrect_count"
    t.json     "review_items_errors"
    t.integer  "reviewed_by_operator_id"
    t.string   "review_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "comment"
    t.json     "review_full_auto_errors"
    t.string   "review_full_auto_custom_error"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "event_operator_interactions", force: true do |t|
    t.json     "event_infos"
    t.json     "modifications_done"
    t.integer  "operator_id"
    t.datetime "done_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "event_title_reviews", force: true do |t|
    t.integer  "messages_thread_id"
    t.string   "status"
    t.text     "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events", force: true do |t|
    t.string   "email"
    t.string   "calendar_nature"
    t.text     "event_id"
    t.text     "calendar_id"
    t.string   "classification"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "features", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "active_mode", default: "none"
    t.text     "active_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "geo_zones", force: true do |t|
    t.string   "label"
    t.string   "country_code"
    t.string   "country"
    t.integer  "population"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "kind"
    t.string   "timezone"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "julie_actions", force: true do |t|
    t.integer  "message_classification_id"
    t.string   "action_nature"
    t.text     "date_times",                        default: "[]"
    t.text     "text"
    t.boolean  "done",                              default: false
    t.boolean  "pending",                           default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "processed_in"
    t.text     "calendar_id"
    t.text     "event_id"
    t.text     "events",                            default: "[]"
    t.boolean  "deleted_event",                     default: false
    t.string   "event_url"
    t.string   "calendar_login_username"
    t.integer  "server_message_id"
    t.text     "generated_text"
    t.boolean  "event_from_invitation",             default: false
    t.string   "event_from_invitation_organizer"
    t.boolean  "date_suggestions_full_ai",          default: false
    t.json     "ai_filters_results",                default: {}
    t.json     "ai_call_status"
    t.json     "date_times_from_ai"
    t.boolean  "date_suggestions_full_ai_capacity"
  end

  add_index "julie_actions", ["message_classification_id"], name: "index_julie_actions_on_message_classification_id", using: :btree

  create_table "julie_aliases", force: true do |t|
    t.string   "email"
    t.string   "name"
    t.text     "signature_fr"
    t.text     "signature_en"
    t.text     "footer_fr"
    t.text     "footer_en"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "message_classifications", force: true do |t|
    t.string   "classification"
    t.integer  "message_id"
    t.string   "operator"
    t.boolean  "validated",                  default: false
    t.string   "appointment_nature"
    t.text     "summary"
    t.integer  "duration"
    t.text     "location"
    t.text     "attendees",                  default: "[]"
    t.text     "notes"
    t.text     "constraints"
    t.text     "date_times",                 default: "[]"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locale"
    t.string   "timezone"
    t.integer  "processed_in"
    t.string   "location_nature"
    t.boolean  "private",                    default: false
    t.text     "other_notes"
    t.text     "constraints_data",           default: "[]"
    t.boolean  "client_agreement",           default: false
    t.boolean  "attendees_are_noticed",      default: false
    t.text     "number_to_call"
    t.string   "review_status"
    t.text     "call_instructions",          default: "[]"
    t.string   "thread_status"
    t.text     "follow_up_data"
    t.string   "title_preference"
    t.json     "location_coordinates",       default: []
    t.boolean  "using_meeting_room",         default: false
    t.json     "meeting_room_details"
    t.boolean  "using_restaurant_booking",   default: false
    t.json     "restaurant_booking_details"
    t.boolean  "location_changed"
    t.json     "virtual_resource_used"
    t.json     "before_update_data"
    t.json     "verified_dates_by_ai"
    t.text     "annotated_reply"
    t.string   "language_level"
    t.boolean  "asap_constraint",            default: false
    t.string   "identifier"
    t.json     "passed_conditions"
    t.json     "client_on_trip"
  end

  add_index "message_classifications", ["identifier"], name: "index_message_classifications_on_identifier", using: :btree
  add_index "message_classifications", ["message_id"], name: "index_message_classifications_on_message_id", using: :btree

  create_table "message_interpretations", force: true do |t|
    t.string   "question"
    t.text     "raw_response"
    t.integer  "message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "error"
  end

  add_index "message_interpretations", ["message_id"], name: "index_message_interpretations_on_message_id", using: :btree

  create_table "messages", force: true do |t|
    t.integer  "messages_thread_id"
    t.datetime "received_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "archived",             default: false
    t.text     "reply_all_recipients"
    t.boolean  "from_me",              default: false
    t.integer  "server_message_id"
    t.datetime "request_at"
    t.string   "allowed_attendees",    default: [],    array: true
    t.string   "auto_email_kind"
  end

  add_index "messages", ["messages_thread_id"], name: "index_messages_on_messages_thread_id", using: :btree
  add_index "messages", ["server_message_id"], name: "index_messages_on_server_message_id", using: :btree

  create_table "messages_threads", force: true do |t|
    t.string   "account_email"
    t.boolean  "in_inbox",                             default: false
    t.string   "locale"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "subject"
    t.text     "snippet"
    t.string   "account_name"
    t.boolean  "sent_to_admin",                        default: false
    t.text     "to_admin_message"
    t.integer  "locked_by_operator_id"
    t.datetime "locked_at"
    t.integer  "server_thread_id"
    t.string   "server_version"
    t.boolean  "delegated_to_support",                 default: false
    t.boolean  "should_follow_up",                     default: false
    t.text     "follow_up_instruction"
    t.integer  "last_operator_id"
    t.datetime "event_booked_date"
    t.string   "status"
    t.boolean  "to_be_merged",                         default: false
    t.integer  "to_be_merged_operator_id"
    t.boolean  "was_merged",                           default: false
    t.datetime "follow_up_reminder_date"
    t.boolean  "handled_by_ai",                        default: false
    t.datetime "request_date"
    t.integer  "messages_count",                       default: 0
    t.boolean  "handled_by_automation",                default: false
    t.boolean  "is_multi_clients",                     default: false
    t.string   "computed_recipients",                  default: [],    array: true
    t.string   "accounts_candidates",                  default: [],    array: true
    t.boolean  "account_request_auto_email_sent",      default: false
    t.boolean  "account_association_merging_possible", default: false
    t.json     "linked_attendees",                     default: {}
    t.string   "clients_in_recipients",                default: [],    array: true
    t.boolean  "has_been_sent_to_admin",               default: false
    t.string   "allowed_attendees",                    default: [],    array: true
    t.string   "accounts_candidates_primary_list",     default: [],    array: true
    t.string   "accounts_candidates_secondary_list",   default: [],    array: true
    t.string   "merging_account_candidates",           default: [],    array: true
    t.string   "tags",                                 default: [],    array: true
  end

  create_table "operator_actions", force: true do |t|
    t.integer  "target_id"
    t.string   "target_type"
    t.integer  "operator_id"
    t.integer  "messages_thread_id"
    t.string   "nature"
    t.datetime "initiated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "operator_actions_group_id"
    t.string   "sub_nature"
    t.text     "message"
  end

  add_index "operator_actions", ["operator_actions_group_id"], name: "index_operator_actions_on_operator_actions_group_id", using: :btree

  create_table "operator_actions_groups", force: true do |t|
    t.integer  "operator_id"
    t.integer  "messages_thread_id"
    t.string   "label"
    t.integer  "target_id"
    t.string   "target_type"
    t.string   "review_status"
    t.integer  "review_notation"
    t.text     "review_comment"
    t.datetime "initiated_at"
    t.integer  "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "group_review_status"
    t.boolean  "duration_edited",         default: false
    t.integer  "reviewed_by_operator_id"
    t.datetime "finished_at"
  end

  add_index "operator_actions_groups", ["operator_id"], name: "index_operator_actions_groups_on_operator_id", using: :btree

  create_table "operator_presences", force: true do |t|
    t.integer  "operator_id"
    t.datetime "date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_review",   default: false
  end

  create_table "operators", force: true do |t|
    t.string   "email"
    t.string   "name"
    t.string   "encrypted_password"
    t.string   "salt"
    t.string   "privilege"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                      default: false
    t.boolean  "ips_whitelist_enabled",       default: true
    t.boolean  "enabled",                     default: true
    t.string   "color",                       default: "#ffffff"
    t.boolean  "planning_access",             default: false
    t.boolean  "in_formation",                default: false
    t.boolean  "manager_access",              default: false
    t.boolean  "operator_of_the_month",       default: false
    t.boolean  "can_see_operators_in_review", default: false
  end

  create_table "settings", force: true do |t|
    t.string   "var",                   null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
