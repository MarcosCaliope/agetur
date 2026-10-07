class ApplicationController < ActionController::Base
  # Every page requires a signed-in User or Admin unless its controller opts
  # out: Devise's own controllers, the public site and the namespaced
  # back-offices (which run their own authenticate_user!/authenticate_admin!).
  before_action :authenticate_user_or_admin!, unless: :devise_controller?

  private

  def authenticate_user_or_admin!
    authenticate_user! unless admin_signed_in?
  end
end
