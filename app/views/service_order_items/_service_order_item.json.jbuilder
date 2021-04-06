json.extract! service_order_item, :id, :service_order_id, :nomepax, :documenttype, :document, :hotel_id, :apto, :qtdepax, :hour, :phone, :vendor_id, :agency_id, :amount, :amountpay, :amountcomission, :comments, :created_at, :updated_at
json.url service_order_item_url(service_order_item, format: :json)
