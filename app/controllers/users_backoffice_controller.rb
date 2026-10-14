class UsersBackofficeController < ApplicationController
    skip_before_action :authenticate_user_or_admin!, :verificar_permissao!
    before_action :authenticate_user!
    layout 'users_backoffice'
end
