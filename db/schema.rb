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

ActiveRecord::Schema.define(version: 20160121111006) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "client_contacts", force: true do |t|
    t.string   "client_email",           null: false
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
  end

  add_index "client_contacts", ["client_email", "email"], name: "index_client_contacts_on_client_email_and_email", unique: true, using: :btree

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

  create_table "event_title_reviews", force: true do |t|
    t.integer  "messages_thread_id"
    t.string   "status"
    t.string   "title"
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

  create_table "julie_actions", force: true do |t|
    t.integer  "message_classification_id"
    t.string   "action_nature"
    t.text     "date_times",                default: "[]"
    t.text     "text"
    t.boolean  "done",                      default: false
    t.boolean  "pending",                   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "processed_in"
    t.text     "calendar_id"
    t.text     "event_id"
    t.text     "events",                    default: "[]"
    t.boolean  "deleted_event",             default: false
    t.string   "event_url"
    t.string   "calendar_login_username"
    t.integer  "server_message_id"
  end

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
    t.boolean  "validated",             default: false
    t.string   "appointment_nature"
    t.string   "summary"
    t.integer  "duration"
    t.text     "location"
    t.text     "attendees",             default: "[]"
    t.text     "notes"
    t.text     "constraints"
    t.text     "date_times",            default: "[]"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "locale"
    t.string   "timezone"
    t.integer  "processed_in"
    t.string   "location_nature"
    t.boolean  "private",               default: false
    t.text     "other_notes"
    t.text     "constraints_data",      default: "[]"
    t.boolean  "client_agreement",      default: false
    t.boolean  "attendees_are_noticed", default: false
    t.text     "number_to_call"
    t.string   "review_status"
    t.text     "call_instructions",     default: "[]"
    t.string   "thread_status"
    t.text     "follow_up_data"
  end

  create_table "messages", force: true do |t|
    t.integer  "messages_thread_id"
    t.datetime "received_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "archived",             default: false
    t.text     "reply_all_recipients"
    t.boolean  "from_me",              default: false
    t.integer  "server_message_id"
  end

  create_table "messages_threads", force: true do |t|
    t.string   "account_email"
    t.boolean  "in_inbox",              default: false
    t.string   "locale"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subject"
    t.text     "snippet"
    t.string   "account_name"
    t.boolean  "delegated_to_founders", default: false
    t.text     "to_founders_message"
    t.integer  "locked_by_operator_id"
    t.datetime "locked_at"
    t.integer  "server_thread_id"
    t.string   "server_version"
    t.boolean  "delegated_to_support",  default: false
    t.boolean  "should_follow_up",      default: false
    t.text     "follow_up_instruction"
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
  end

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
    t.boolean  "active",             default: false
  end

  create_table "staging_event_attendees", force: true do |t|
    t.string   "event_id"
    t.text     "attendees"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "staging_server_messages", force: true do |t|
    t.integer  "messages_thread_id"
    t.text     "server_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
