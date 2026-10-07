class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # Not :registerable: users are created from the console, never by self sign-up.
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable
end
