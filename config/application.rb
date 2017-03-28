require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Inv
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    config.assets.enabled = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Krasnoyarsk'
    config.i18n.default_locale = :ru

    # Загрузка всех файлов из
    # config.autoload_paths << Rails.root.join('lib').to_s

    # Provides support for Cross-Origin Resource Sharing (CORS)
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins   'http://***REMOVED***', 'https://***REMOVED***.***REMOVED***.ru'
        resource  '/inventory/***REMOVED***_invents/init/*', :headers => :any, :methods => [:get]
        resource  '/inventory/***REMOVED***_invents/show_division_data/*', :headers => :any, :methods => [:get]
        resource  '/inventory/***REMOVED***_invents/get_data_from_audit/*', :headers => :any, :methods => [:get]
        resource  '/inventory/***REMOVED***_invents/create_workplace/', :headers => :any, :methods => [:post]
        resource  '/inventory/***REMOVED***_invents/edit_workplace/*', :headers => :any, :methods => [:get]
        resource  '/inventory/***REMOVED***_invents/update_workplace/*', :headers => :any, :methods => [:patch]
        resource  '/inventory/***REMOVED***_invents/delete_workplace/*', :headers => :any, :methods => [:delete]
        resource  '/inventory/***REMOVED***_invents/generate_pdf/*', :headers => :any, :methods => [:get]
      end
    end
  end
end

# Настройка серверных переменных окружения
SERVER_CONFIG = YAML.load_file("#{Rails.root.join('config', 'server.yml').to_s}")[Rails.env]