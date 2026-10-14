class SiteController < ApplicationController
    skip_before_action :authenticate_user_or_admin!, :verificar_permissao!
    layout 'site'
end
