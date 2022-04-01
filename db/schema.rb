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

ActiveRecord::Schema.define(version: 2022_04_01_142936) do

  create_table "admins", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "agencies", charset: "utf8mb3", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", charset: "utf8mb3", force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_id"], name: "index_companies_on_state_id"
  end

  create_table "customers", charset: "utf8mb3", force: :cascade do |t|
    t.string "nome"
    t.string "email"
    t.string "phone"
    t.string "document"
    t.string "comments"
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "state_id"
    t.index ["state_id"], name: "index_customers_on_state_id"
  end

  create_table "destinations", charset: "utf8mb3", force: :cascade do |t|
    t.string "description"
    t.integer "distance"
    t.float "valuenormal"
    t.float "valuenormalchd"
    t.float "valuenet"
    t.float "valuenetchd"
    t.float "valuecard"
    t.float "valuecardchd"
    t.bigint "state_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_id"], name: "index_destinations_on_state_id"
  end

  create_table "drivers", charset: "utf8mb3", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "city"
    t.string "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hotels", charset: "utf8mb3", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "comments"
    t.float "Valordiaria"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "service_order_items", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "service_order_id"
    t.string "nomepax"
    t.string "documenttype"
    t.string "document"
    t.bigint "hotel_id"
    t.string "apto"
    t.integer "qtdepax"
    t.string "hour"
    t.string "phone"
    t.bigint "vendor_id"
    t.bigint "agency_id"
    t.float "amount"
    t.float "amountpay"
    t.float "amountcomission"
    t.string "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "customer_id"
    t.index ["agency_id"], name: "index_service_order_items_on_agency_id"
    t.index ["customer_id"], name: "index_service_order_items_on_customer_id"
    t.index ["hotel_id"], name: "index_service_order_items_on_hotel_id"
    t.index ["service_order_id"], name: "index_service_order_items_on_service_order_id"
    t.index ["vendor_id"], name: "index_service_order_items_on_vendor_id"
  end

  create_table "service_orders", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "data"
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
    t.boolean "bpagto"
    t.boolean "bcancelado"
    t.integer "icapacidade"
    t.integer "ibloqueio"
    t.integer "iflgaberto"
    t.integer "ilitros"
    t.string "sobservacoes"
    t.string "sodometroinicio"
    t.string "sodometrofim"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_service_orders_on_destination_id"
    t.index ["driver_id"], name: "index_service_orders_on_driver_id"
    t.index ["tourguide_id"], name: "index_service_orders_on_tourguide_id"
    t.index ["vehicle_id"], name: "index_service_orders_on_vehicle_id"
  end

  create_table "sorder_items", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "sorder_id"
    t.string "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["agency_id"], name: "index_sorder_items_on_agency_id"
    t.index ["customer_id"], name: "index_sorder_items_on_customer_id"
    t.index ["hotel_id"], name: "index_sorder_items_on_hotel_id"
    t.index ["sorder_id"], name: "index_sorder_items_on_sorder_id"
    t.index ["vendor_id"], name: "index_sorder_items_on_vendor_id"
  end

  create_table "sorders", charset: "utf8mb3", force: :cascade do |t|
    t.datetime "data"
    t.string "sobservacoes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "dataos"
    t.index ["company_id"], name: "index_sorders_on_company_id"
    t.index ["destination_id"], name: "index_sorders_on_destination_id"
    t.index ["driver_id"], name: "index_sorders_on_driver_id"
    t.index ["tourguide_id"], name: "index_sorders_on_tourguide_id"
    t.index ["vehicle_id"], name: "index_sorders_on_vehicle_id"
  end

  create_table "states", charset: "utf8mb3", force: :cascade do |t|
    t.string "uf"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tourguides", charset: "utf8mb3", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vehicles", charset: "utf8mb3", force: :cascade do |t|
    t.string "license"
    t.string "brand"
    t.string "smodel"
    t.string "year"
    t.string "color"
    t.string "city"
    t.bigint "state_id"
    t.string "comments"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_id"], name: "index_vehicles_on_state_id"
  end

  create_table "vendors", charset: "utf8mb3", force: :cascade do |t|
    t.string "sname"
    t.string "email"
    t.string "address"
    t.string "phone"
    t.string "comments"
    t.float "commission"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "companies", "states"
  add_foreign_key "customers", "states"
  add_foreign_key "destinations", "states"
  add_foreign_key "service_order_items", "agencies"
  add_foreign_key "service_order_items", "customers"
  add_foreign_key "service_order_items", "hotels"
  add_foreign_key "service_order_items", "service_orders"
  add_foreign_key "service_order_items", "vendors"
  add_foreign_key "service_orders", "destinations"
  add_foreign_key "service_orders", "drivers"
  add_foreign_key "service_orders", "tourguides"
  add_foreign_key "service_orders", "vehicles"
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
  add_foreign_key "vehicles", "states"
end
