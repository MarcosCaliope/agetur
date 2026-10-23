# Production runs on Render (render.yaml; see docs/deploy-render.md). Every
# setting that differs per deploy comes from an environment variable.
Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. Rake tasks automatically ignore this option.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # No credentials are used: the committed config/master.key is exposed (see
  # CLAUDE.md), so the secret comes from SECRET_KEY_BASE instead.

  # Render has no web server in front of Puma, so Rails serves /public
  # (precompiled assets and the vendored gentelella theme).
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Receipts and logos (config/storage.yml): "r2" on Render, whose own disk
  # is wiped on every deploy. "local" only where storage/ is kept.
  config.active_storage.service = ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym

  # Render terminates TLS: trust its X-Forwarded-Proto, redirect HTTP to
  # HTTPS and mark cookies secure. The health check is called over HTTP.
  config.assume_ssl = true
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT, which Render collects.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new($stdout).tap { |log| log.formatter = ::Logger::Formatter.new })

  # Mail (Devise's password reset) through any SMTP provider. Without
  # SMTP_ADDRESS nothing is sent.
  host = ENV["APP_HOST"].presence || ENV["RENDER_EXTERNAL_HOSTNAME"]
  config.action_mailer.default_url_options = { host: host, protocol: "https" } if host
  config.action_mailer.perform_caching = false
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV["SMTP_ADDRESS"], port: ENV.fetch("SMTP_PORT", 587).to_i,
      user_name: ENV["SMTP_USERNAME"], password: ENV["SMTP_PASSWORD"],
      authentication: :plain, enable_starttls_auto: true
    }
    config.action_mailer.raise_delivery_errors = true
  else
    config.action_mailer.perform_deliveries = false
  end

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
