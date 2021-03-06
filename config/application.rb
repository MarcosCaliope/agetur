require_relative 'boot'

require 'rails/all'
#require 'pdfkit'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Agetur
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    #Time::DATE_FORMATS[:default] = "%d/%m/%Y %H:%M"
    #Date::DATE_FORMATS[:default] = "%d/%m/%Y"
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
require 'pdfkit'
module RailsPdf
  # Ativa o PDFKit
  class Application < Rails::Application
      config.middleware.use PDFKit::Middleware
    end
end