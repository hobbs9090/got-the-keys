# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_09_093000) do
  create_table "admins", force: :cascade do |t|
    t.integer "consumed_timestep"
    t.datetime "created_at", precision: nil
    t.string "email"
    t.string "encrypted_password"
    t.string "language"
    t.json "otp_backup_codes"
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "otp_secret"
    t.datetime "updated_at", precision: nil
  end

  create_table "appointment_events", force: :cascade do |t|
    t.integer "admin_id"
    t.integer "appointment_id", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "from_status"
    t.text "message"
    t.json "metadata"
    t.datetime "occurred_at", null: false
    t.string "to_status"
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_appointment_events_on_admin_id"
    t.index ["appointment_id"], name: "index_appointment_events_on_appointment_id"
    t.index ["event_type"], name: "index_appointment_events_on_event_type"
  end

  create_table "appointments", force: :cascade do |t|
    t.string "access_token", null: false
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.integer "duration_minutes", default: 45, null: false
    t.text "internal_notes"
    t.text "notes"
    t.integer "property_id", null: false
    t.string "public_reference", null: false
    t.datetime "reminder_sent_at"
    t.datetime "requested_time", null: false
    t.datetime "scheduled_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.string "visit_outcome"
    t.index ["access_token"], name: "index_appointments_on_access_token", unique: true
    t.index ["admin_id"], name: "index_appointments_on_admin_id"
    t.index ["customer_email"], name: "index_appointments_on_customer_email"
    t.index ["property_id"], name: "index_appointments_on_property_id"
    t.index ["public_reference"], name: "index_appointments_on_public_reference", unique: true
    t.index ["status", "scheduled_at"], name: "index_appointments_on_status_and_scheduled_at"
    t.index ["visit_outcome"], name: "index_appointments_on_visit_outcome"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.string "actor_label"
    t.integer "admin_id"
    t.integer "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.json "metadata"
    t.datetime "occurred_at", null: false
    t.integer "property_id"
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["admin_id"], name: "index_audit_logs_on_admin_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable"
    t.index ["property_id", "occurred_at"], name: "index_audit_logs_on_property_id_and_occurred_at"
    t.index ["property_id"], name: "index_audit_logs_on_property_id"
  end

  create_table "availability_windows", force: :cascade do |t|
    t.integer "capacity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.string "kind", default: "open", null: false
    t.string "label"
    t.text "notes"
    t.integer "property_id", null: false
    t.datetime "starts_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_availability_windows_on_kind"
    t.index ["property_id", "starts_at", "ends_at"], name: "index_availability_windows_on_property_and_range"
    t.index ["property_id"], name: "index_availability_windows_on_property_id"
  end

  create_table "booking_configurations", force: :cascade do |t|
    t.string "active_demo_scenario_key", default: "baseline", null: false
    t.string "admin_two_factor_mode", default: "disabled", null: false
    t.integer "booking_window_days", default: 21, null: false
    t.integer "buffer_minutes", default: 15, null: false
    t.datetime "created_at", null: false
    t.datetime "last_demo_data_action_at"
    t.integer "lead_time_hours", default: 4, null: false
    t.string "office_closes_at", default: "18:00", null: false
    t.string "office_opens_at", default: "09:00", null: false
    t.string "open_weekdays", default: "1,2,3,4,5,6", null: false
    t.integer "slot_duration_minutes", default: 45, null: false
    t.datetime "updated_at", null: false
  end

  create_table "demo_scenario_runs", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.string "initiated_by_email"
    t.string "scenario_key"
    t.string "source", default: "catalog", null: false
    t.json "summary_data"
    t.datetime "updated_at", null: false
    t.index ["scenario_key"], name: "index_demo_scenario_runs_on_scenario_key"
  end

  create_table "enquiries", force: :cascade do |t|
    t.integer "admin_id"
    t.datetime "contacted_at"
    t.datetime "created_at", null: false
    t.string "customer_email"
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.text "internal_notes"
    t.string "lead_reference", null: false
    t.text "message", null: false
    t.integer "property_id", null: false
    t.string "source_type", default: "general_enquiry", null: false
    t.boolean "spam", default: false, null: false
    t.string "spam_reason"
    t.string "status", default: "new", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_enquiries_on_admin_id"
    t.index ["lead_reference"], name: "index_enquiries_on_lead_reference", unique: true
    t.index ["property_id", "created_at"], name: "index_enquiries_on_property_id_and_created_at"
    t.index ["property_id"], name: "index_enquiries_on_property_id"
    t.index ["source_type"], name: "index_enquiries_on_source_type"
    t.index ["spam"], name: "index_enquiries_on_spam"
    t.index ["status"], name: "index_enquiries_on_status"
  end

  create_table "floor_plans", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "floor_plans"
    t.string "label"
    t.integer "position", default: 0, null: false
    t.integer "property_id"
    t.datetime "updated_at", precision: nil
    t.index ["property_id", "position"], name: "index_floor_plans_on_property_id_and_position"
    t.index ["property_id"], name: "index_floor_plans_on_property_id"
  end

  create_table "notification_logs", force: :cascade do |t|
    t.integer "appointment_id"
    t.text "body_preview"
    t.datetime "created_at", null: false
    t.integer "enquiry_id"
    t.text "error_message"
    t.string "event_type", null: false
    t.json "metadata"
    t.string "recipient_email"
    t.string "status", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_notification_logs_on_appointment_id"
    t.index ["enquiry_id"], name: "index_notification_logs_on_enquiry_id"
    t.index ["status"], name: "index_notification_logs_on_status"
  end

  create_table "offer_events", force: :cascade do |t|
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "from_status"
    t.text "message"
    t.datetime "occurred_at", null: false
    t.integer "offer_id", null: false
    t.string "to_status"
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_offer_events_on_admin_id"
    t.index ["offer_id"], name: "index_offer_events_on_offer_id"
  end

  create_table "offers", force: :cascade do |t|
    t.integer "admin_id"
    t.integer "amount", null: false
    t.string "buyer_email", null: false
    t.string "buyer_name", null: false
    t.string "buyer_phone", null: false
    t.string "chain_position"
    t.datetime "created_at", null: false
    t.datetime "decision_made_at"
    t.text "internal_notes"
    t.text "notes"
    t.integer "property_id", null: false
    t.string "public_reference", null: false
    t.string "status", default: "received", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_offers_on_admin_id"
    t.index ["property_id"], name: "index_offers_on_property_id"
    t.index ["public_reference"], name: "index_offers_on_public_reference", unique: true
    t.index ["status"], name: "index_offers_on_status"
  end

  create_table "photos", force: :cascade do |t|
    t.string "caption"
    t.datetime "created_at", precision: nil
    t.string "image_filename"
    t.integer "position", default: 0, null: false
    t.boolean "primary", default: false, null: false
    t.integer "property_id"
    t.datetime "updated_at", precision: nil
    t.index ["property_id", "position"], name: "index_photos_on_property_id_and_position"
    t.index ["property_id"], name: "index_photos_on_property_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.integer "asking_price"
    t.date "available_from"
    t.integer "bathrooms", default: 1, null: false
    t.integer "bedrooms"
    t.string "council_tax_band"
    t.string "country"
    t.string "county"
    t.datetime "created_at", precision: nil
    t.integer "deposit_amount"
    t.boolean "featured", default: false, null: false
    t.integer "floor_area_sq_ft"
    t.string "furnishing"
    t.string "image_file_name"
    t.integer "lease_length_years"
    t.string "listing_state", default: "published", null: false
    t.string "listing_tagline"
    t.string "outdoor_space"
    t.string "parking"
    t.boolean "pets_allowed", default: false, null: false
    t.string "postcode"
    t.text "property_description"
    t.string "property_type", default: "House", null: false
    t.datetime "published_at"
    t.integer "refurbished_year"
    t.string "sale_status"
    t.integer "service_charge_amount"
    t.string "tenure"
    t.string "town_city"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.integer "year_built"
    t.index ["available_from"], name: "index_properties_on_available_from"
    t.index ["bedrooms"], name: "index_properties_on_bedrooms"
    t.index ["featured"], name: "index_properties_on_featured"
    t.index ["listing_state"], name: "index_properties_on_listing_state"
    t.index ["refurbished_year"], name: "index_properties_on_refurbished_year"
    t.index ["sale_status", "asking_price"], name: "index_properties_on_sale_status_and_price"
    t.index ["user_id"], name: "index_properties_on_user_id"
    t.index ["year_built"], name: "index_properties_on_year_built"
  end

  create_table "property_documents", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.string "file_name", null: false
    t.integer "position", default: 0, null: false
    t.integer "property_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "visibility", default: "private", null: false
    t.index ["category"], name: "index_property_documents_on_category"
    t.index ["property_id", "position"], name: "index_property_documents_on_property_id_and_position"
    t.index ["property_id"], name: "index_property_documents_on_property_id"
    t.index ["visibility"], name: "index_property_documents_on_visibility"
  end

  create_table "rental_application_events", force: :cascade do |t|
    t.integer "admin_id"
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "from_status"
    t.text "message"
    t.datetime "occurred_at", null: false
    t.integer "rental_application_id", null: false
    t.string "to_status"
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_rental_application_events_on_admin_id"
    t.index ["rental_application_id"], name: "index_rental_application_events_on_rental_application_id"
  end

  create_table "rental_applications", force: :cascade do |t|
    t.integer "admin_id"
    t.text "affordability_notes"
    t.string "applicant_email", null: false
    t.string "applicant_name", null: false
    t.string "applicant_phone", null: false
    t.datetime "created_at", null: false
    t.datetime "decision_made_at"
    t.boolean "guarantor_available", default: false, null: false
    t.boolean "guarantor_required", default: false, null: false
    t.text "internal_notes"
    t.date "move_in_date", null: false
    t.text "notes"
    t.integer "property_id", null: false
    t.string "public_reference", null: false
    t.string "status", default: "received", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_rental_applications_on_admin_id"
    t.index ["property_id"], name: "index_rental_applications_on_property_id"
    t.index ["public_reference"], name: "index_rental_applications_on_public_reference", unique: true
    t.index ["status"], name: "index_rental_applications_on_status"
  end

  create_table "saved_properties", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["property_id"], name: "index_saved_properties_on_property_id"
    t.index ["user_id", "property_id"], name: "index_saved_properties_on_user_id_and_property_id", unique: true
    t.index ["user_id"], name: "index_saved_properties_on_user_id"
  end

  create_table "saved_searches", force: :cascade do |t|
    t.boolean "alerts_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "locale", default: "en", null: false
    t.integer "max_price"
    t.integer "min_bedrooms"
    t.integer "min_price"
    t.string "sale_status"
    t.string "search_query"
    t.string "sort"
    t.string "town_city"
    t.datetime "updated_at", null: false
    t.index ["alerts_enabled"], name: "index_saved_searches_on_alerts_enabled"
    t.index ["email"], name: "index_saved_searches_on_email"
    t.index ["sale_status"], name: "index_saved_searches_on_sale_status"
    t.index ["town_city"], name: "index_saved_searches_on_town_city"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0
    t.string "first_name"
    t.string "language"
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "locked_at", precision: nil
    t.string "mobile_number"
    t.integer "properties_count"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", precision: nil
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "viewing_times", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "end_time", precision: nil
    t.integer "property_id"
    t.datetime "start_time", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["property_id"], name: "index_viewing_times_on_property_id"
  end

  add_foreign_key "appointment_events", "admins"
  add_foreign_key "appointment_events", "appointments"
  add_foreign_key "appointments", "admins"
  add_foreign_key "appointments", "properties"
  add_foreign_key "audit_logs", "admins"
  add_foreign_key "audit_logs", "properties"
  add_foreign_key "availability_windows", "properties"
  add_foreign_key "enquiries", "admins"
  add_foreign_key "enquiries", "properties"
  add_foreign_key "notification_logs", "appointments"
  add_foreign_key "notification_logs", "enquiries"
  add_foreign_key "offer_events", "admins"
  add_foreign_key "offer_events", "offers"
  add_foreign_key "offers", "admins"
  add_foreign_key "offers", "properties"
  add_foreign_key "property_documents", "properties"
  add_foreign_key "rental_application_events", "admins"
  add_foreign_key "rental_application_events", "rental_applications"
  add_foreign_key "rental_applications", "admins"
  add_foreign_key "rental_applications", "properties"
  add_foreign_key "saved_properties", "properties"
  add_foreign_key "saved_properties", "users"
end
