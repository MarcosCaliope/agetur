class SiteController < ApplicationController
    skip_before_action :authenticate_user_or_admin!
    layout 'site'
end
