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

ActiveRecord::Schema[7.2].define(version: 2026_10_08_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "agencies", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sistger_id"
    t.string "short_name"
    t.string "neighborhood"
    t.string "city"
    t.bigint "state_id"
    t.string "zipcode"
    t.string "phone2"
    t.string "fax"
    t.string "contact"
    t.string "document"
    t.float "commission"
    t.bigint "vendor_id"
    t.index ["sistger_id"], name: "index_agencies_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_agencies_on_state_id"
    t.index ["vendor_id"], name: "index_agencies_on_vendor_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "cnpj"
    t.string "address"
    t.string "phone"
    t.string "city"
    t.bigint "state_id"
    t.integer "osmodel"
    t.integer "osdupla"
    t.string "email"
    t.string "site"
    t.string "logoform"
    t.string "logoentrada"
    t.integer "iretorno"
    t.integer "osshowcan"
    t.integer "osshowcanrel"
    t.integer "osshowrep"
    t.string "osincludechdcalc"
    t.string "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sistger_id"
    t.string "short_name"
    t.string "state_registration"
    t.index ["sistger_id"], name: "index_companies_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_companies_on_state_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "nome"
    t.string "email"
    t.string "phone"
    t.string "document"
    t.string "comments"
    t.string "city"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "state_id"
    t.integer "sistger_id"
    t.string "state_registration"
    t.string "address"
    t.string "neighborhood"
    t.string "zipcode"
    t.string "phone2"
    t.string "fax"
    t.string "contact"
    t.string "website"
    t.string "billing_address"
    t.string "billing_neighborhood"
    t.string "billing_city"
    t.bigint "billing_state_id"
    t.string "billing_zipcode"
    t.string "billing_phone"
    t.string "billing_phone2"
    t.string "billing_fax"
    t.index ["billing_state_id"], name: "index_customers_on_billing_state_id"
    t.index ["sistger_id"], name: "index_customers_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_customers_on_state_id"
  end

  create_table "destinations", force: :cascade do |t|
    t.string "description"
    t.integer "distance"
    t.float "valuenormal"
    t.float "valuenormalchd"
    t.float "valuenet"
    t.float "valuenetchd"
    t.float "valuecard"
    t.float "valuecardchd"
    t.bigint "state_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sistger_id"
    t.float "value_combo"
    t.float "value_combo_chd"
    t.float "value_net_combo"
    t.float "value_net_combo_chd"
    t.index ["sistger_id"], name: "index_destinations_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_destinations_on_state_id"
  end

  create_table "drivers", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "city"
    t.string "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "short_name"
    t.string "neighborhood"
    t.bigint "state_id"
    t.string "zipcode"
    t.string "phone2"
    t.string "fax"
    t.string "contact"
    t.string "document"
    t.integer "sistger_id"
    t.index ["sistger_id"], name: "index_drivers_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_drivers_on_state_id"
  end

  create_table "hotels", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "comments"
    t.float "Valordiaria"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sistger_id"
    t.string "short_name"
    t.string "neighborhood"
    t.string "city"
    t.bigint "state_id"
    t.string "zipcode"
    t.string "phone2"
    t.string "fax"
    t.string "contact"
    t.string "document"
    t.index ["sistger_id"], name: "index_hotels_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_hotels_on_state_id"
  end

  create_table "sorder_items", force: :cascade do |t|
    t.bigint "sorder_id"
    t.string "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "customer_id"
    t.string "documenttype"
    t.string "document"
    t.bigint "hotel_id"
    t.string "apto"
    t.bigint "vendor_id"
    t.bigint "agency_id"
    t.string "phone"
    t.integer "qtdepax"
    t.integer "qtdechd"
    t.string "hour"
    t.float "amount"
    t.float "amountpay"
    t.float "amountcomission"
    t.float "amountcomissionpay"
    t.float "amountcomissionrep"
    t.float "amountcomissionreppay"
    t.string "snomepax"
    t.string "scancelado"
    t.integer "sistger_numero"
    t.integer "sistger_sequencial"
    t.index ["agency_id"], name: "index_sorder_items_on_agency_id"
    t.index ["customer_id"], name: "index_sorder_items_on_customer_id"
    t.index ["hotel_id"], name: "index_sorder_items_on_hotel_id"
    t.index ["sistger_numero", "sistger_sequencial"], name: "index_sorder_items_on_sistger_numero_and_sistger_sequencial", unique: true
    t.index ["sorder_id"], name: "index_sorder_items_on_sorder_id"
    t.index ["vendor_id"], name: "index_sorder_items_on_vendor_id"
  end

  create_table "sorders", force: :cascade do |t|
    t.datetime "data", precision: nil
    t.string "sobservacoes"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "destination_id"
    t.bigint "tourguide_id"
    t.bigint "driver_id"
    t.bigint "vehicle_id"
    t.float "valorguia"
    t.float "valormotorista"
    t.float "valorpedagio"
    t.float "valordespesas"
    t.float "valorcombustivel"
    t.float "valoros"
    t.float "valorfinalos"
    t.bigint "company_id"
    t.integer "sistger_id"
    t.index ["company_id"], name: "index_sorders_on_company_id"
    t.index ["destination_id"], name: "index_sorders_on_destination_id"
    t.index ["driver_id"], name: "index_sorders_on_driver_id"
    t.index ["sistger_id"], name: "index_sorders_on_sistger_id", unique: true
    t.index ["tourguide_id"], name: "index_sorders_on_tourguide_id"
    t.index ["vehicle_id"], name: "index_sorders_on_vehicle_id"
  end

  create_table "states", force: :cascade do |t|
    t.string "uf"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "tourguides", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "short_name"
    t.string "neighborhood"
    t.string "city"
    t.bigint "state_id"
    t.string "zipcode"
    t.string "phone2"
    t.string "fax"
    t.string "contact"
    t.string "document"
    t.integer "sistger_id"
    t.index ["sistger_id"], name: "index_tourguides_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_tourguides_on_state_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.string "license"
    t.string "brand"
    t.string "smodel"
    t.string "year"
    t.string "color"
    t.string "city"
    t.bigint "state_id"
    t.string "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sistger_id"
    t.string "vehicle_type"
    t.string "manufacture_year"
    t.string "capacity"
    t.string "tank"
    t.string "chassis"
    t.string "odometer"
    t.string "renavam"
    t.integer "licensing_year"
    t.date "acquired_on"
    t.string "insurance_kit"
    t.index ["sistger_id"], name: "index_vehicles_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_vehicles_on_state_id"
  end

  create_table "vendor_destinations", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.bigint "destination_id", null: false
    t.float "commission"
    t.float "net_adult"
    t.float "net_chd"
    t.float "net_adult_card"
    t.float "net_chd_card"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_vendor_destinations_on_destination_id"
    t.index ["vendor_id", "destination_id"], name: "index_vendor_destinations_on_vendor_id_and_destination_id", unique: true
    t.index ["vendor_id"], name: "index_vendor_destinations_on_vendor_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "comments"
    t.float "commission"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "sistger_id"
    t.string "short_name"
    t.string "neighborhood"
    t.string "city"
    t.bigint "state_id"
    t.string "zipcode"
    t.string "phone2"
    t.string "fax"
    t.string "contact"
    t.string "document"
    t.string "classification"
    t.boolean "active", default: true, null: false
    t.boolean "no_commission", default: false, null: false
    t.index ["sistger_id"], name: "index_vendors_on_sistger_id", unique: true
    t.index ["state_id"], name: "index_vendors_on_state_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "agencies", "states"
  add_foreign_key "agencies", "vendors"
  add_foreign_key "companies", "states"
  add_foreign_key "customers", "states"
  add_foreign_key "customers", "states", column: "billing_state_id"
  add_foreign_key "destinations", "states"
  add_foreign_key "drivers", "states"
  add_foreign_key "hotels", "states"
  add_foreign_key "sorder_items", "agencies"
  add_foreign_key "sorder_items", "customers"
  add_foreign_key "sorder_items", "hotels"
  add_foreign_key "sorder_items", "sorders"
  add_foreign_key "sorder_items", "vendors"
  add_foreign_key "sorders", "companies"
  add_foreign_key "sorders", "destinations"
  add_foreign_key "sorders", "drivers"
  add_foreign_key "sorders", "tourguides"
  add_foreign_key "sorders", "vehicles"
  add_foreign_key "tourguides", "states"
  add_foreign_key "vehicles", "states"
  add_foreign_key "vendor_destinations", "destinations", on_delete: :cascade
  add_foreign_key "vendor_destinations", "vendors", on_delete: :cascade
  add_foreign_key "vendors", "states"
end
