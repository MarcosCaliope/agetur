ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Records created outside a request (model tests, test setup) belong to
  # the fixtures' company. A request sets its own (DaEmpresa).
  setup { Current.empresa_id = ActiveRecord::FixtureSet.identify(:two) }
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
