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

ActiveRecord::Schema.define(version: 20130805160411) do

  create_table "admins", force: true do |t|
    t.string   "email"
    t.string   "encrypted_password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "language"
  end

  create_table "floor_plans", force: true do |t|
    t.string   "floor_plans"
    t.integer  "property_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "floor_plans", ["property_id"], name: "index_floor_plans_on_property_id"

  create_table "photos", force: true do |t|
    t.string   "image_filename"
    t.integer  "property_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "photos", ["property_id"], name: "index_photos_on_property_id"

  create_table "properties", force: true do |t|
    t.integer  "asking_price"
    t.text     "property_description"
    t.string   "sale_status"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "town_city"
    t.string   "county"
    t.string   "postcode"
    t.string   "country"
    t.string   "image_file_name"
    t.integer  "bedrooms"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "properties", ["bedrooms"], name: "index_properties_on_bedrooms"
  add_index "properties", ["user_id"], name: "index_properties_on_user_id"

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "language"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "mobile_number"
    t.integer  "properties_count"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

  create_table "viewing_times", force: true do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "property_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "viewing_times", ["property_id"], name: "index_viewing_times_on_property_id"

end
