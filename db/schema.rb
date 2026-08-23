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

ActiveRecord::Schema[8.1].define(version: 2026_08_22_231341) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "customers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "customer_type", default: "individual", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "mobile"
    t.text "notes"
    t.uuid "organization_id", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "company_name"], name: "index_customers_on_organization_id_and_company_name"
    t.index ["organization_id", "email"], name: "index_customers_on_organization_id_and_email"
    t.index ["organization_id"], name: "index_customers_on_organization_id"
  end

  create_table "equipment", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "brand"
    t.datetime "created_at", null: false
    t.string "equipment_type", null: false
    t.datetime "last_maintenance_at"
    t.integer "maintenance_interval_days"
    t.string "model"
    t.string "name", null: false
    t.datetime "next_maintenance_at"
    t.text "notes"
    t.uuid "organization_id", null: false
    t.date "purchase_date"
    t.decimal "purchase_price", precision: 12, scale: 2
    t.string "serial_number"
    t.string "status", default: "available", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "active"], name: "index_equipment_on_organization_id_and_active"
    t.index ["organization_id", "equipment_type"], name: "index_equipment_on_organization_id_and_equipment_type"
    t.index ["organization_id", "next_maintenance_at"], name: "index_equipment_on_organization_id_and_next_maintenance_at"
    t.index ["organization_id", "serial_number"], name: "index_equipment_on_organization_id_and_serial_number", unique: true, where: "(serial_number IS NOT NULL)"
    t.index ["organization_id", "status"], name: "index_equipment_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_equipment_on_organization_id"
  end

  create_table "invoice_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.decimal "discount_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.uuid "invoice_id", null: false
    t.integer "position", default: 0, null: false
    t.decimal "quantity", precision: 12, scale: 3, default: "1.0", null: false
    t.uuid "service_item_id"
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_rate", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "unit", null: false
    t.decimal "unit_price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "position"], name: "index_invoice_items_on_invoice_id_and_position", unique: true
    t.index ["invoice_id", "service_item_id"], name: "index_invoice_items_on_invoice_id_and_service_item_id"
    t.index ["invoice_id"], name: "index_invoice_items_on_invoice_id"
    t.index ["service_item_id"], name: "index_invoice_items_on_service_item_id"
  end

  create_table "invoices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "amount_due", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "amount_paid", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.uuid "customer_id", null: false
    t.decimal "discount_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.date "due_date"
    t.date "issue_date", null: false
    t.uuid "job_id"
    t.text "notes"
    t.string "number", null: false
    t.uuid "organization_id", null: false
    t.datetime "paid_at"
    t.string "payment_method"
    t.string "payment_reference"
    t.uuid "quote_id"
    t.uuid "site_id"
    t.string "status", default: "draft", null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["job_id"], name: "index_invoices_on_job_id"
    t.index ["organization_id", "customer_id"], name: "index_invoices_on_organization_id_and_customer_id"
    t.index ["organization_id", "due_date"], name: "index_invoices_on_organization_id_and_due_date"
    t.index ["organization_id", "issue_date"], name: "index_invoices_on_organization_id_and_issue_date"
    t.index ["organization_id", "job_id"], name: "index_invoices_on_organization_id_and_job_id"
    t.index ["organization_id", "number"], name: "index_invoices_on_organization_id_and_number", unique: true
    t.index ["organization_id", "quote_id"], name: "index_invoices_on_organization_id_and_quote_id"
    t.index ["organization_id", "status"], name: "index_invoices_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_invoices_on_organization_id"
    t.index ["quote_id"], name: "index_invoices_on_quote_id"
    t.index ["site_id"], name: "index_invoices_on_site_id"
  end

  create_table "job_assignments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "accepted_at"
    t.boolean "active", default: true, null: false
    t.datetime "assigned_at"
    t.string "assignment_type", default: "primary", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.uuid "job_id", null: false
    t.text "notes"
    t.uuid "organization_id", null: false
    t.string "role", default: "worker", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["job_id", "user_id"], name: "index_job_assignments_on_job_id_and_user_id", unique: true
    t.index ["job_id"], name: "index_job_assignments_on_job_id"
    t.index ["organization_id", "active"], name: "index_job_assignments_on_organization_id_and_active"
    t.index ["organization_id", "job_id"], name: "index_job_assignments_on_organization_id_and_job_id"
    t.index ["organization_id", "user_id"], name: "index_job_assignments_on_organization_id_and_user_id"
    t.index ["organization_id"], name: "index_job_assignments_on_organization_id"
    t.index ["user_id"], name: "index_job_assignments_on_user_id"
  end

  create_table "job_reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_signature"
    t.datetime "customer_signed_at"
    t.datetime "generated_at"
    t.uuid "job_id", null: false
    t.text "observations"
    t.uuid "organization_id", null: false
    t.text "recommendations"
    t.datetime "sent_to_customer_at"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.text "work_performed"
    t.index ["job_id"], name: "index_job_reports_on_job_id"
    t.index ["organization_id", "generated_at"], name: "index_job_reports_on_organization_id_and_generated_at"
    t.index ["organization_id", "job_id"], name: "index_job_reports_on_organization_id_and_job_id"
    t.index ["organization_id", "sent_to_customer_at"], name: "index_job_reports_on_organization_id_and_sent_to_customer_at"
    t.index ["organization_id"], name: "index_job_reports_on_organization_id"
  end

  create_table "job_time_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_minutes"
    t.datetime "ended_at"
    t.string "entry_type", default: "work", null: false
    t.uuid "job_id", null: false
    t.text "notes"
    t.uuid "organization_id", null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["job_id", "user_id", "started_at"], name: "index_job_time_entries_on_job_id_and_user_id_and_started_at"
    t.index ["job_id"], name: "index_job_time_entries_on_job_id"
    t.index ["organization_id", "entry_type"], name: "index_job_time_entries_on_organization_id_and_entry_type"
    t.index ["organization_id", "job_id"], name: "index_job_time_entries_on_organization_id_and_job_id"
    t.index ["organization_id", "user_id", "started_at"], name: "idx_on_organization_id_user_id_started_at_acd37a72ed"
    t.index ["organization_id"], name: "index_job_time_entries_on_organization_id"
    t.index ["user_id"], name: "index_job_time_entries_on_user_id"
  end

  create_table "jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "actual_duration_minutes"
    t.string "address"
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.uuid "customer_id", null: false
    t.text "customer_notes"
    t.text "description"
    t.integer "estimated_duration_minutes"
    t.text "internal_notes"
    t.string "job_type", null: false
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.uuid "organization_id", null: false
    t.string "priority", default: "normal", null: false
    t.uuid "quote_id"
    t.date "scheduled_date"
    t.datetime "scheduled_end_at"
    t.datetime "scheduled_start_at"
    t.uuid "site_id", null: false
    t.datetime "started_at"
    t.string "status", default: "planned", null: false
    t.uuid "team_id"
    t.string "title", null: false
    t.decimal "travel_distance_km", precision: 10, scale: 2
    t.integer "travel_duration_minutes"
    t.datetime "updated_at", null: false
    t.uuid "vehicle_id"
    t.text "weather_notes"
    t.string "weather_risk", default: "unknown", null: false
    t.index ["customer_id"], name: "index_jobs_on_customer_id"
    t.index ["organization_id", "customer_id"], name: "index_jobs_on_organization_id_and_customer_id"
    t.index ["organization_id", "quote_id"], name: "index_jobs_on_organization_id_and_quote_id"
    t.index ["organization_id", "scheduled_date"], name: "index_jobs_on_organization_id_and_scheduled_date"
    t.index ["organization_id", "site_id"], name: "index_jobs_on_organization_id_and_site_id"
    t.index ["organization_id", "status"], name: "index_jobs_on_organization_id_and_status"
    t.index ["organization_id", "team_id", "scheduled_date"], name: "index_jobs_on_organization_id_and_team_id_and_scheduled_date"
    t.index ["organization_id", "vehicle_id", "scheduled_date"], name: "idx_on_organization_id_vehicle_id_scheduled_date_3be971e5af"
    t.index ["organization_id"], name: "index_jobs_on_organization_id"
    t.index ["quote_id"], name: "index_jobs_on_quote_id"
    t.index ["site_id"], name: "index_jobs_on_site_id"
    t.index ["team_id"], name: "index_jobs_on_team_id"
    t.index ["vehicle_id"], name: "index_jobs_on_vehicle_id"
  end

  create_table "organizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "address"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "name", null: false
    t.string "phone"
    t.string "postal_code"
    t.string "slug", null: false
    t.string "timezone", default: "Europe/Paris", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_organizations_on_email", unique: true
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "quote_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.decimal "discount_percentage", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "equipment_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "estimated_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "estimated_duration_minutes"
    t.decimal "labor_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "margin_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "margin_percentage", precision: 5, scale: 2
    t.decimal "material_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "position", default: 0, null: false
    t.decimal "quantity", precision: 12, scale: 3, default: "1.0", null: false
    t.uuid "quote_id", null: false
    t.uuid "service_item_id", null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_rate", precision: 5, scale: 2, default: "20.0", null: false
    t.decimal "total_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "unit", default: "unit", null: false
    t.decimal "unit_price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["quote_id", "position"], name: "index_quote_items_on_quote_id_and_position"
    t.index ["quote_id", "service_item_id"], name: "index_quote_items_on_quote_id_and_service_item_id"
    t.index ["quote_id"], name: "index_quote_items_on_quote_id"
    t.index ["service_item_id"], name: "index_quote_items_on_service_item_id"
  end

  create_table "quotes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.uuid "customer_id", null: false
    t.text "description"
    t.decimal "discount_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "estimated_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "estimated_margin_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "estimated_margin_percentage", precision: 5, scale: 2
    t.date "issue_date", null: false
    t.text "notes"
    t.string "number", null: false
    t.uuid "organization_id", null: false
    t.datetime "rejected_at"
    t.uuid "site_id", null: false
    t.string "status", default: "draft", null: false
    t.decimal "subtotal", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tax_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.string "title", null: false
    t.decimal "total_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.date "valid_until"
    t.index ["customer_id"], name: "index_quotes_on_customer_id"
    t.index ["organization_id", "customer_id"], name: "index_quotes_on_organization_id_and_customer_id"
    t.index ["organization_id", "issue_date"], name: "index_quotes_on_organization_id_and_issue_date"
    t.index ["organization_id", "number"], name: "index_quotes_on_organization_id_and_number", unique: true
    t.index ["organization_id", "site_id"], name: "index_quotes_on_organization_id_and_site_id"
    t.index ["organization_id", "status"], name: "index_quotes_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_quotes_on_organization_id"
    t.index ["site_id"], name: "index_quotes_on_site_id"
  end

  create_table "service_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category_type"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.uuid "organization_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "code"], name: "index_service_categories_on_organization_id_and_code", unique: true
    t.index ["organization_id", "name"], name: "index_service_categories_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_service_categories_on_organization_id"
  end

  create_table "service_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.decimal "default_margin_percentage", precision: 5, scale: 2
    t.decimal "default_quantity", precision: 12, scale: 3
    t.decimal "default_unit_price", precision: 12, scale: 2
    t.text "description"
    t.decimal "equipment_cost", precision: 12, scale: 2
    t.integer "estimated_duration_minutes"
    t.decimal "labor_cost", precision: 12, scale: 2
    t.decimal "material_cost", precision: 12, scale: 2
    t.string "name", null: false
    t.uuid "organization_id", null: false
    t.decimal "overhead_cost", precision: 12, scale: 2
    t.integer "position", default: 0, null: false
    t.uuid "service_category_id", null: false
    t.string "unit", default: "unit", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "code"], name: "index_service_items_on_organization_id_and_code", unique: true
    t.index ["organization_id", "name"], name: "index_service_items_on_organization_id_and_name"
    t.index ["organization_id", "service_category_id"], name: "index_service_items_on_organization_id_and_service_category_id"
    t.index ["organization_id"], name: "index_service_items_on_organization_id"
    t.index ["service_category_id"], name: "index_service_items_on_service_category_id"
  end

  create_table "sites", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "country", default: "FR", null: false
    t.datetime "created_at", null: false
    t.uuid "customer_id", null: false
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "name", null: false
    t.text "notes"
    t.uuid "organization_id", null: false
    t.string "postal_code"
    t.string "site_type"
    t.decimal "surface_area", precision: 12, scale: 2
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_sites_on_customer_id"
    t.index ["organization_id", "customer_id"], name: "index_sites_on_organization_id_and_customer_id"
    t.index ["organization_id", "name"], name: "index_sites_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_sites_on_organization_id"
  end

  create_table "team_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.uuid "organization_id", null: false
    t.string "role", default: "member", null: false
    t.date "start_date"
    t.uuid "team_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["organization_id", "active"], name: "index_team_memberships_on_organization_id_and_active"
    t.index ["organization_id", "team_id"], name: "index_team_memberships_on_organization_id_and_team_id"
    t.index ["organization_id", "user_id"], name: "index_team_memberships_on_organization_id_and_user_id"
    t.index ["organization_id"], name: "index_team_memberships_on_organization_id"
    t.index ["team_id", "user_id"], name: "index_team_memberships_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.string "color"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.uuid "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "code"], name: "index_teams_on_organization_id_and_code", unique: true
    t.index ["organization_id", "name"], name: "index_teams_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_teams_on_organization_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "last_sign_in_at"
    t.uuid "organization_id", null: false
    t.string "password_digest"
    t.string "phone"
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  create_table "vehicles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "brand"
    t.decimal "capacity", precision: 12, scale: 2
    t.datetime "created_at", null: false
    t.decimal "fuel_consumption", precision: 8, scale: 2
    t.string "fuel_type"
    t.string "model"
    t.string "name", null: false
    t.text "notes"
    t.uuid "organization_id", null: false
    t.string "registration_number", null: false
    t.datetime "updated_at", null: false
    t.string "vehicle_type"
    t.integer "year"
    t.index ["organization_id", "active"], name: "index_vehicles_on_organization_id_and_active"
    t.index ["organization_id", "name"], name: "index_vehicles_on_organization_id_and_name"
    t.index ["organization_id", "registration_number"], name: "index_vehicles_on_organization_id_and_registration_number", unique: true
    t.index ["organization_id"], name: "index_vehicles_on_organization_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customers", "organizations"
  add_foreign_key "equipment", "organizations"
  add_foreign_key "invoice_items", "invoices"
  add_foreign_key "invoice_items", "service_items"
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "jobs"
  add_foreign_key "invoices", "organizations"
  add_foreign_key "invoices", "quotes"
  add_foreign_key "invoices", "sites"
  add_foreign_key "job_assignments", "jobs"
  add_foreign_key "job_assignments", "organizations"
  add_foreign_key "job_assignments", "users"
  add_foreign_key "job_reports", "jobs"
  add_foreign_key "job_reports", "organizations"
  add_foreign_key "job_time_entries", "jobs"
  add_foreign_key "job_time_entries", "organizations"
  add_foreign_key "job_time_entries", "users"
  add_foreign_key "jobs", "customers"
  add_foreign_key "jobs", "organizations"
  add_foreign_key "jobs", "quotes"
  add_foreign_key "jobs", "sites"
  add_foreign_key "jobs", "teams"
  add_foreign_key "jobs", "vehicles"
  add_foreign_key "quote_items", "quotes"
  add_foreign_key "quote_items", "service_items"
  add_foreign_key "quotes", "customers"
  add_foreign_key "quotes", "organizations"
  add_foreign_key "quotes", "sites"
  add_foreign_key "service_categories", "organizations"
  add_foreign_key "service_items", "organizations"
  add_foreign_key "service_items", "service_categories"
  add_foreign_key "sites", "customers"
  add_foreign_key "sites", "organizations"
  add_foreign_key "team_memberships", "organizations"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "teams", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "vehicles", "organizations"
end
