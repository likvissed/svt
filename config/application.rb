require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Inv
  class Application < Rails::Application
    ENV['http_proxy'] = ""
    ENV['https_proxy'] = ""
    ENV['HTTP_PROXY'] = ""
    ENV['HTTPS_PROXY'] = ""

    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    config.assets.enabled = true

    config.force_ssl = true
    config.ssl_options = { domain: '***REMOVED***.ru' }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Krasnoyarsk'
    config.active_record.default_timezone = :local
    config.i18n.default_locale = :ru

    # Загрузка всех файлов из
    config.autoload_paths << Rails.root.join('app', 'services').to_s
    config.autoload_paths << Rails.root.join('app', 'modules').to_s
    config.autoload_paths << Rails.root.join('app', 'states').to_s
    config.autoload_paths << Rails.root.join('lib', 'validators').to_s
    config.autoload_paths << Rails.root.join('lib', 'strategy').to_s

    # Provides support for Cross-Origin Resource Sharing (CORS)
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'https://***REMOVED***.***REMOVED***.ru', 'https://***REMOVED***.npopm``.ru',
                'https://***REMOVED***.***REMOVED***.ru', 'https://***REMOVED***.npopm.ru',
                'https://***REMOVED***.***REMOVED***.ru', 'https://***REMOVED***.npopm.ru', 'http://***REMOVED***',
                /\Ahttps:\/\/***REMOVED***(.*)\.***REMOVED***\.ru\z/
        resource '/invent/***REMOVED***_invents/svt_access*', headers: :any, methods: [:get]
        resource '/invent/***REMOVED***_invents/init_properties*', headers: :any, methods: [:get]
        resource '/invent/***REMOVED***_invents/show_division_data*', headers: :any, methods: [:get]
        resource '/invent/***REMOVED***_invents/pc_config_from_audit*', headers: :any, methods: [:get]
        resource '/invent/***REMOVED***_invents/pc_config_from_user*', headers: :any, methods: [:post]
        resource '/invent/***REMOVED***_invents/create_workplace*', headers: :any, methods: [:post]
        resource '/invent/***REMOVED***_invents/edit_workplace*', headers: :any, methods: [:get]
        resource '/invent/***REMOVED***_invents/update_workplace*', headers: :any, methods: [:patch]
        resource '/invent/***REMOVED***_invents/destroy_workplace*', headers: :any, methods: [:delete]
        resource '/invent/***REMOVED***_invents/generate_pdf*', headers: :any, methods: [:get]
        resource '/invent/***REMOVED***_invents/get_pc_script*', headers: :any, methods: [:get]
        resource '/invent/***REMOVED***_invents/existing_item*', headers: :any, methods: [:get]
        resource '/invent/***REMOVED***_invents/invent_item*', headers: :any, methods: [:get]
        resource '/user_isses*', headers: :any,  methods: [:get]
        resource '/api/v1/invent/items*', headers: :any,  methods: [:get]
      end
    end

    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec,
                       fixtures: true,
                       view_spec: false,
                       helper_specs: false,
                       routing_specs: false,
                       request_specs: false,
                       controller_spec: true
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end

    config.action_cable.url = "wss://#{ENV['HOSTNAME']}.***REMOVED***.ru/cable"

    config.cache_store = :redis_store, "#{ENV['REDIS_URL']}2/cache"

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              ENV['ACTION_MAILER_ADDRESS'],
      port:                 25,
      user_name:            ENV['GMAIL_USERNAME'],
      password:             ENV['GMAIL_PASSWORD'],
      authentication:       'plain',
      openssl_verify_mode: 'none'
    }
  end
end
