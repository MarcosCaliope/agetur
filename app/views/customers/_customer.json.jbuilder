json.extract! customer, :id, :nome, :email, :phone, :document, :comments, :city, :created_at, :updated_at
json.url customer_url(customer, format: :json)
