json.extract! tourguide, :id, :sname, :email, :address, :phone, :comments, :created_at, :updated_at
json.url tourguide_url(tourguide, format: :json)
