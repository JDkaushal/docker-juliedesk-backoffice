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

ActiveRecord::Schema.define(version: 20150128083858) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.text     "event_ids",                 default: "[]"
    t.text     "text"
    t.boolean  "done",                      default: false
    t.boolean  "pending",                   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "message_classifications", force: true do |t|
    t.string   "classification"
    t.integer  "message_id"
    t.string   "operator"
    t.boolean  "validated",          default: false
    t.string   "appointment_nature"
    t.string   "summary"
    t.integer  "duration"
    t.text     "location"
    t.text     "attendees",          default: "[]"
    t.text     "notes"
    t.text     "constraints"
    t.text     "date_times",         default: "[]"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", force: true do |t|
    t.string   "google_message_id"
    t.integer  "messages_thread_id"
    t.datetime "received_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "archived",           default: false
  end

  create_table "messages_threads", force: true do |t|
    t.string   "google_thread_id"
    t.string   "account_email"
    t.boolean  "in_inbox",          default: false
    t.string   "locale"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "google_history_id"
    t.string   "subject"
    t.text     "snippet"
  end

end
