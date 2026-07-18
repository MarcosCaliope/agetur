class DropServiceOrders < ActiveRecord::Migration[5.2]
  def up
    drop_table :service_order_items
    drop_table :service_orders
  end

  def down
    create_table "service_orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
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
    add_foreign_key "service_orders", "destinations"
    add_foreign_key "service_orders", "drivers"
    add_foreign_key "service_orders", "tourguides"
    add_foreign_key "service_orders", "vehicles"

    create_table "service_order_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3" do |t|
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
    add_foreign_key "service_order_items", "agencies"
    add_foreign_key "service_order_items", "customers"
    add_foreign_key "service_order_items", "hotels"
    add_foreign_key "service_order_items", "service_orders"
    add_foreign_key "service_order_items", "vendors"
  end
end
