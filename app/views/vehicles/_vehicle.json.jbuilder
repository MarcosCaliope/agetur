json.extract! vehicle, :id, :license, :brand, :smodel, :year, :color, :city, :state_id, :comments, :created_at, :updated_at
json.url vehicle_url(vehicle, format: :json)
