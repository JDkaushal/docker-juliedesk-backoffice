Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_assets  = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :tests

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  ENV['CONSCIENCE_BASE_PATH'] = 'test_ai_conscience_path'
  ENV['CONSCIENCE_API_KEY'] = 'conscience_api_key'
  ENV['API_KEY'] = 'testpikeyferferfrefer'

  ENV['JULIEDESK_APP_API_KEY'] = 'frfrfrf'

  ENV['JULIEDESK_APP_BASE_PATH'] = 'https://test-app.herokuapp.com'
  ENV['DOMAIN_NAME'] = 'test-backoffice.herokuapp.com'

  ENV['STAGING_APP'] = nil
  ENV['REDIS_URL_FOR_ACCOUNTS_CACHE'] = 'redis://127.0.0.1/0'

  ENV['EMAIL_SERVER_BASE_PATH'] = 'http://test.com'

  ENV['DEFAULT_JULIE_ALIAS_EMAIL'] = 'julie@juliedesk.com'
  ENV['COMMON_JULIE_ALIAS_EMAIL'] = 'julie@juliedesk.com'
  ENV['SEGMENT_WRITE_KEY'] = '123'
  ENV['LIMIT_DURATION_FOR_SYNCING_TAG'] = '4'
end
