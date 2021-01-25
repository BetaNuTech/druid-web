# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_02_01_230614) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "articletype"
    t.string "category"
    t.boolean "published", default: false
    t.string "title"
    t.text "body"
    t.string "slug"
    t.uuid "user_id"
    t.string "contextid", default: "hidden"
    t.string "audience", default: "all"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["articletype"], name: "index_articles_on_articletype"
    t.index ["contextid"], name: "index_articles_on_contextid"
    t.index ["created_at"], name: "index_articles_on_created_at"
    t.index ["title"], name: "index_articles_on_title"
    t.index ["user_id", "published", "audience", "articletype", "contextid", "created_at"], name: "article_info_idx"
  end

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

  create_table "contact_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_id", null: false
    t.uuid "user_id", null: false
    t.uuid "article_id"
    t.string "article_type"
    t.string "description"
    t.datetime "timestamp", null: false
    t.boolean "first_contact", default: false, null: false
    t.integer "lead_time", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["first_contact", "timestamp"], name: "contact_events_contact_and_timestamp"
    t.index ["lead_id", "user_id", "first_contact", "timestamp"], name: "contact_events_general_idx"
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

  create_table "duplicate_leads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "reference_id"
    t.uuid "lead_id"
    t.index ["lead_id"], name: "index_duplicate_leads_on_lead_id"
    t.index ["reference_id", "lead_id"], name: "index_duplicate_leads_on_reference_id_and_lead_id", unique: true
    t.index ["reference_id"], name: "index_duplicate_leads_on_reference_id"
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

  create_table "flipflop_features", force: :cascade do |t|
    t.string "key", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "lead_actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "glyph"
    t.boolean "is_contact", default: false
    t.string "state_affinity", default: "all"
    t.boolean "notify", default: false
    t.index ["state_affinity"], name: "index_lead_actions_on_state_affinity"
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
    t.boolean "optin_sms", default: false
    t.datetime "optin_sms_date"
  end

  create_table "lead_referral_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lead_referrals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_id", null: false
    t.uuid "lead_referral_source_id"
    t.uuid "referrable_id"
    t.string "referrable_type"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_lead_referrals_on_lead_id"
    t.index ["referrable_id", "referrable_type"], name: "idx_referrable"
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

  create_table "lead_transitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_id", null: false
    t.string "last_state", null: false
    t.string "current_state", null: false
    t.integer "classification"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remoteid"
    t.index ["last_state", "current_state", "created_at"], name: "state_xtn"
    t.index ["last_state", "current_state"], name: "index_lead_transitions_on_last_state_and_current_state"
    t.index ["lead_id"], name: "index_lead_transitions_on_lead_id"
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
    t.string "phone1_type", default: "Cell"
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
    t.integer "classification"
    t.datetime "follow_up_at"
    t.index ["classification"], name: "index_leads_on_classification"
    t.index ["follow_up_at"], name: "index_leads_on_follow_up_at"
    t.index ["phone1", "phone2", "first_name", "last_name", "email"], name: "lead_dedupe_idx"
    t.index ["priority"], name: "index_leads_on_priority"
    t.index ["remoteid"], name: "index_leads_on_remoteid"
    t.index ["state"], name: "index_leads_on_state"
  end

  create_table "marketing_expenses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "property_id", null: false
    t.uuid "marketing_source_id", null: false
    t.string "invoice"
    t.text "description"
    t.decimal "fee_total", null: false
    t.integer "fee_type", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["property_id", "marketing_source_id", "start_date"], name: "query_idx"
  end

  create_table "marketing_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true
    t.uuid "property_id", null: false
    t.uuid "lead_source_id"
    t.string "name", null: false
    t.text "description"
    t.string "tracking_code"
    t.string "tracking_email"
    t.string "tracking_number"
    t.string "destination_number"
    t.integer "fee_type", default: 0, null: false
    t.decimal "fee_rate", default: "0.0"
    t.date "start_date", null: false
    t.date "end_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "phone_lead_source_id"
    t.uuid "email_lead_source_id"
    t.index ["property_id", "name"], name: "index_marketing_sources_on_property_id_and_name", unique: true
    t.index ["tracking_email"], name: "index_marketing_sources_on_tracking_email"
    t.index ["tracking_number"], name: "index_marketing_sources_on_tracking_number"
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
    t.boolean "shared", default: true
    t.index ["shared", "user_id"], name: "index_message_templates_on_shared_and_user_id"
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
    t.boolean "incoming"
    t.integer "since_last"
    t.integer "classification", default: 0
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
    t.integer "classification", default: 0
    t.index ["classification"], name: "index_notes_on_classification"
    t.index ["user_id", "notable_id", "notable_type"], name: "index_notes_on_user_id_and_notable_id_and_notable_type"
  end

  create_table "phone_numbers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "number"
    t.string "prefix", default: "1"
    t.integer "category", default: 0
    t.integer "availability", default: 0
    t.uuid "phoneable_id"
    t.string "phoneable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phoneable_type", "phoneable_id"], name: "index_phone_numbers_on_phoneable_type_and_phoneable_id"
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
    t.uuid "team_id"
    t.boolean "call_lead_generation", default: true
    t.string "maintenance_phone"
    t.jsonb "working_hours"
    t.string "timezone", default: "UTC", null: false
    t.index ["active"], name: "index_properties_on_active"
    t.index ["team_id"], name: "index_properties_on_team_id"
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

  create_table "property_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "property_id"
    t.uuid "user_id"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id", "user_id"], name: "index_property_users_on_property_id_and_user_id", unique: true
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

  create_table "roommates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "lead_id"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "email"
    t.integer "relationship", default: 0
    t.boolean "sms_allowed", default: false
    t.boolean "email_allowed", default: true
    t.integer "occupancy", default: 0
    t.string "remoteid"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.string "remoteid"
    t.uuid "article_id"
    t.string "article_type"
    t.boolean "notify", default: false
    t.datetime "notified_at"
    t.text "notification_message"
    t.index ["article_type", "article_id"], name: "scheduled_actions_article_idx"
    t.index ["notify", "notified_at"], name: "notification_idx"
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
    t.integer "duration"
    t.time "end_time"
  end

  create_table "statistics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "fact", null: false
    t.uuid "quantifiable_id", null: false
    t.string "quantifiable_type", null: false
    t.integer "resolution", default: 1440, null: false
    t.decimal "value", null: false
    t.datetime "time_start", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["created_at"], name: "index_statistics_on_created_at"
    t.index ["fact", "quantifiable_id", "quantifiable_type", "resolution", "time_start"], name: "statistics_general_idx", unique: true
  end

  create_table "team_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id"
    t.uuid "user_id"
    t.uuid "teamrole_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_team_users_on_user_id", unique: true
  end

  create_table "teamroles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_teamroles_on_slug", unique: true
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "description"
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
    t.boolean "model", default: false
    t.index ["property_id", "unit"], name: "index_units_on_property_id_and_unit", unique: true
    t.index ["remoteid"], name: "index_units_on_remoteid"
  end

  create_table "user_impressions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "reference"
    t.string "path"
    t.string "referrer"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["reference", "created_at"], name: "index_user_impressions_on_reference_and_created_at"
    t.index ["user_id", "reference"], name: "index_user_impressions_on_user_id_and_reference"
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
    t.text "signature"
    t.jsonb "enabled_features", default: {}
    t.jsonb "appsettings", default: {}
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
    t.boolean "deactivated", default: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "duplicate_leads", "leads", column: "reference_id", name: "duplicate_leads_reference_id_fk"
  add_foreign_key "duplicate_leads", "leads", name: "duplicate_leads_lead_id_fk"
  add_foreign_key "engagement_policies", "properties", name: "engagement_policies_property_id_fk"
  add_foreign_key "engagement_policy_action_compliances", "scheduled_actions", name: "engagement_policy_action_compliances_scheduled_action_id_fk"
  add_foreign_key "engagement_policy_action_compliances", "users", name: "engagement_policy_action_compliances_user_id_fk"
  add_foreign_key "engagement_policy_actions", "engagement_policies", name: "engagement_policy_actions_engagement_policy_id_fk"
  add_foreign_key "engagement_policy_actions", "lead_actions", name: "engagement_policy_actions_lead_action_id_fk"
  add_foreign_key "lead_preferences", "leads", name: "lead_preferences_lead_id_fk"
  add_foreign_key "lead_preferences", "unit_types", name: "lead_preferences_unit_type_id_fk"
  add_foreign_key "lead_referrals", "lead_referral_sources", name: "lead_referrals_lead_referral_source_id_fk"
  add_foreign_key "lead_referrals", "leads", name: "lead_referrals_lead_id_fk"
  add_foreign_key "lead_transitions", "leads", name: "lead_transitions_lead_id_fk"
  add_foreign_key "leads", "lead_sources", name: "leads_lead_source_id_fk"
  add_foreign_key "leads", "properties", name: "leads_property_id_fk"
  add_foreign_key "leads", "users", name: "leads_user_id_fk"
  add_foreign_key "message_deliveries", "message_types", name: "message_deliveries_message_type_id_fk"
  add_foreign_key "message_deliveries", "messages", name: "message_deliveries_message_id_fk"
  add_foreign_key "message_delivery_adapters", "message_types", name: "message_delivery_adapters_message_type_id_fk"
  add_foreign_key "message_templates", "message_types", name: "message_templates_message_type_id_fk"
  add_foreign_key "message_templates", "users", name: "message_templates_user_id_fk"
  add_foreign_key "messages", "message_types", name: "messages_message_type_id_fk"
  add_foreign_key "messages", "users", column: "read_by_user_id", name: "messages_read_by_user_id_fk"
  add_foreign_key "messages", "users", name: "messages_user_id_fk"
  add_foreign_key "notes", "lead_actions", name: "notes_lead_action_id_fk"
  add_foreign_key "notes", "reasons", name: "notes_reason_id_fk"
  add_foreign_key "notes", "users", name: "notes_user_id_fk"
  add_foreign_key "properties", "teams", name: "properties_team_id_fk"
  add_foreign_key "property_listings", "lead_sources", column: "source_id", name: "property_listings_source_id_fk"
  add_foreign_key "property_listings", "properties", name: "property_listings_property_id_fk"
  add_foreign_key "property_users", "properties", name: "property_users_property_id_fk"
  add_foreign_key "property_users", "users", name: "property_users_user_id_fk"
  add_foreign_key "resident_details", "residents", name: "resident_details_resident_id_fk"
  add_foreign_key "residents", "leads", name: "residents_lead_id_fk"
  add_foreign_key "residents", "properties", name: "residents_property_id_fk"
  add_foreign_key "residents", "units", name: "residents_unit_id_fk"
  add_foreign_key "scheduled_actions", "engagement_policy_action_compliances", name: "scheduled_actions_engagement_policy_action_compliance_id_fk", on_delete: :cascade
  add_foreign_key "scheduled_actions", "engagement_policy_actions", name: "scheduled_actions_engagement_policy_action_id_fk"
  add_foreign_key "scheduled_actions", "lead_actions", name: "scheduled_actions_lead_action_id_fk"
  add_foreign_key "scheduled_actions", "reasons", name: "scheduled_actions_reason_id_fk"
  add_foreign_key "scheduled_actions", "scheduled_actions", column: "originator_id", name: "scheduled_actions_originator_id_fk"
  add_foreign_key "scheduled_actions", "users", name: "scheduled_actions_user_id_fk"
  add_foreign_key "team_users", "teamroles", name: "team_users_teamrole_id_fk"
  add_foreign_key "team_users", "teams", name: "team_users_team_id_fk"
  add_foreign_key "team_users", "users", name: "team_users_user_id_fk"
  add_foreign_key "unit_types", "properties", name: "unit_types_property_id_fk"
  add_foreign_key "units", "properties", name: "units_property_id_fk"
  add_foreign_key "units", "rental_types", name: "units_rental_type_id_fk"
  add_foreign_key "units", "unit_types", name: "units_unit_type_id_fk"
  add_foreign_key "user_profiles", "users", name: "user_profiles_user_id_fk"
  add_foreign_key "users", "roles", name: "users_role_id_fk"
end
