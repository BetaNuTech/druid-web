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

ActiveRecord::Schema.define(version: 2018_08_29_153438) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "audits", force: :cascade do |t|
    t.uuid "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_id", "associated_type"], name: "associated_index"
    t.index ["auditable_id", "auditable_type"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "engagement_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "property_id"
    t.string "lead_state"
    t.text "description"
    t.integer "version", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "lead_state", "property_id", "version"], name: "covering"
  end

  create_table "engagement_policy_action_compliances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "scheduled_action_id"
    t.uuid "user_id"
    t.string "state", default: "pending"
    t.datetime "expires_at"
    t.datetime "completed_at"
    t.decimal "score"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "epac_expires_at"
    t.index ["state"], name: "epac_state"
    t.index ["user_id", "scheduled_action_id"], name: "epac_user_id_sa_id"
  end

  create_table "engagement_policy_actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "engagement_policy_id"
    t.uuid "lead_action_id"
    t.text "description"
    t.decimal "deadline"
    t.integer "retry_count", default: 0
    t.decimal "retry_delay", default: "0.0"
    t.string "retry_delay_multiplier", default: "none"
    t.decimal "score", default: "1.0"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["engagement_policy_id", "lead_action_id"], name: "engagement_policy_action_covering"
  end

  create_table "lead_actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "glyph"
    t.boolean "is_contact", default: false
  end

  create_table "lead_preferences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_id"
    t.integer "min_area"
    t.integer "max_area"
    t.decimal "min_price"
    t.decimal "max_price"
    t.datetime "move_in"
    t.decimal "baths"
    t.boolean "pets"
    t.boolean "smoker"
    t.boolean "washerdryer"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "beds"
    t.text "raw_data"
    t.uuid "unit_type_id"
    t.boolean "optout_email", default: false
    t.datetime "optout_email_date"
  end

  create_table "lead_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.boolean "incoming"
    t.string "slug"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_token"
    t.index ["active", "api_token"], name: "index_lead_sources_on_active_and_api_token"
  end

  create_table "leads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "lead_source_id"
    t.string "title"
    t.string "first_name"
    t.string "last_name"
    t.string "referral"
    t.string "state"
    t.text "notes"
    t.datetime "first_comm"
    t.datetime "last_comm"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "property_id"
    t.string "phone1"
    t.string "phone2"
    t.string "fax"
    t.string "email"
    t.integer "priority", default: 1
    t.string "phone1_type"
    t.string "phone2_type"
    t.string "phone1_tod"
    t.string "phone2_tod"
    t.datetime "dob"
    t.string "id_number"
    t.string "id_state"
    t.string "remoteid"
    t.string "middle_name"
    t.datetime "conversion_date"
    t.json "call_log"
    t.datetime "call_log_updated_at"
    t.index ["priority"], name: "index_leads_on_priority"
    t.index ["remoteid"], name: "index_leads_on_remoteid"
    t.index ["state"], name: "index_leads_on_state"
  end

  create_table "message_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "message_id"
    t.uuid "message_type_id"
    t.integer "attempt"
    t.datetime "attempted_at"
    t.string "status"
    t.text "log"
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_message_deliveries_on_message_id"
  end

  create_table "message_delivery_adapters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "message_type_id", null: false
    t.string "slug", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "api_token"
    t.index ["api_token"], name: "index_message_delivery_adapters_on_api_token"
    t.index ["message_type_id"], name: "index_message_delivery_adapters_on_message_type_id"
    t.index ["slug"], name: "index_message_delivery_adapters_on_slug", unique: true
  end

  create_table "message_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "message_type_id", null: false
    t.uuid "user_id"
    t.string "name", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "message_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "html", default: false
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "messageable_id"
    t.string "messageable_type"
    t.uuid "user_id", null: false
    t.string "state", default: "draft", null: false
    t.string "senderid", null: false
    t.string "recipientid", null: false
    t.uuid "message_template_id"
    t.string "subject", null: false
    t.text "body", null: false
    t.datetime "delivered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "message_type_id"
    t.string "threadid"
    t.datetime "read_at"
    t.uuid "read_by_user_id"
    t.index ["messageable_type", "messageable_id"], name: "message_messageable"
    t.index ["state"], name: "index_messages_on_state"
    t.index ["threadid"], name: "index_messages_on_threadid"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "lead_action_id"
    t.uuid "reason_id"
    t.uuid "notable_id"
    t.string "notable_type"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "notable_id", "notable_type"], name: "index_notes_on_user_id_and_notable_id_and_notable_type"
  end

  create_table "properties", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "address1"
    t.string "address2"
    t.string "address3"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.string "organization"
    t.string "contact_name"
    t.string "phone"
    t.string "fax"
    t.string "email"
    t.integer "units"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.string "website"
    t.string "school_district"
    t.text "amenities"
    t.string "application_url"
    t.index ["active"], name: "index_properties_on_active"
  end

  create_table "property_agents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "property_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.index ["user_id", "property_id"], name: "index_property_agents_on_user_id_and_property_id", unique: true
  end

  create_table "property_listings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code"
    t.string "description"
    t.uuid "property_id"
    t.uuid "source_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "code"], name: "index_property_listings_on_active_and_code"
    t.index ["property_id", "source_id", "active"], name: "index_property_listings_on_property_id_and_source_id_and_active"
  end

  create_table "reasons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rental_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resident_details", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "resident_id"
    t.string "phone1"
    t.string "phone1_type"
    t.string "phone1_tod"
    t.string "phone2"
    t.string "phone2_type"
    t.string "phone2_tod"
    t.string "email"
    t.string "encrypted_ssn"
    t.string "encrypted_ssn_iv"
    t.string "id_number"
    t.string "id_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resident_id"], name: "index_resident_details_on_resident_id"
  end

  create_table "residents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_id"
    t.uuid "property_id"
    t.uuid "unit_id"
    t.string "residentid"
    t.string "status"
    t.date "dob"
    t.string "title"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "status", "unit_id"], name: "index_residents_on_property_id_and_status_and_unit_id"
    t.index ["residentid"], name: "index_residents_on_residentid", unique: true
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scheduled_actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "target_id"
    t.string "target_type"
    t.uuid "originator_id"
    t.uuid "lead_action_id"
    t.uuid "reason_id"
    t.uuid "engagement_policy_action_id"
    t.uuid "engagement_policy_action_compliance_id"
    t.text "description"
    t.datetime "completed_at"
    t.string "state", default: "pending"
    t.integer "attempt", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["originator_id"], name: "index_scheduled_actions_on_originator_id"
    t.index ["target_id", "target_type"], name: "scheduled_action_target"
    t.index ["user_id"], name: "index_scheduled_actions_on_user_id"
  end

  create_table "schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "schedulable_type"
    t.uuid "schedulable_id"
    t.date "date"
    t.time "time"
    t.string "rule"
    t.string "interval"
    t.text "day"
    t.text "day_of_week"
    t.datetime "until"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "unit_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.uuid "property_id"
    t.string "remoteid"
    t.integer "bathrooms"
    t.integer "bedrooms"
    t.decimal "market_rent", default: "0.0"
    t.decimal "sqft", default: "0.0"
    t.index ["property_id", "name"], name: "index_unit_types_on_property_id_and_name", unique: true
    t.index ["remoteid"], name: "index_unit_types_on_remoteid"
  end

  create_table "units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "property_id"
    t.uuid "unit_type_id"
    t.uuid "rental_type_id"
    t.string "unit"
    t.integer "floor"
    t.integer "sqft"
    t.integer "bedrooms"
    t.text "description"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remoteid"
    t.integer "bathrooms"
    t.string "occupancy", default: "vacant"
    t.string "lease_status", default: "available"
    t.date "available_on"
    t.decimal "market_rent", default: "0.0"
    t.index ["property_id", "unit"], name: "index_units_on_property_id_and_unit", unique: true
    t.index ["remoteid"], name: "index_units_on_remoteid"
  end

  create_table "user_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "name_prefix"
    t.string "first_name"
    t.string "last_name"
    t.string "name_suffix"
    t.string "slack"
    t.string "cell_phone"
    t.string "office_phone"
    t.string "fax"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "role_id"
    t.string "timezone", default: "UTC"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

end
