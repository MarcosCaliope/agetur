require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include Devise::Test::IntegrationHelpers

  # Headless by default; SYSTEM_TEST_HEADED=1 opens a visible window.
  driven_by :selenium, using: ENV["SYSTEM_TEST_HEADED"] ? :chrome : :headless_chrome, screen_size: [1400, 1400] do |options|
    # Rails only resolves chromedriver's path, which makes Selenium skip
    # Selenium Manager, and with it the path of the Chrome it downloaded
    # (~/.cache/selenium) when none is installed. Ask for it here.
    options.binary ||= Selenium::WebDriver::SeleniumManager.binary_paths("--browser", "chrome")["browser_path"]
  end
end
