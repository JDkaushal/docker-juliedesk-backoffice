require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module JuliedeskBackoffice
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('lib/*')

    config.angular_templates.ignore_prefix = %w(angular_templates/)

    config.middleware.insert_before 0, Rack::Cors, :debug => true, :logger => (-> { Rails.logger }) do
      allow do
        origins '*'

        resource '*',
                 :headers => :any,
                 :methods => [:get, :post, :delete, :put, :options, :head],
                 :max_age => 0
      end
    end

    # Allow serving gzipped assets and html to increase performances
    config.middleware.use Rack::Deflater

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'automatic_reply_emails', '*.yml').to_s]
    # config.i18n.default_locale = :de

    config.action_view.automatically_disable_submit_tag = false
  end
end
