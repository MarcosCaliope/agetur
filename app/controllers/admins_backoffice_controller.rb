class AdminsBackofficeController < ApplicationController
    skip_before_action :authenticate_user_or_admin!
    before_action :authenticate_admin!
    layout 'admins_backoffice'
end
