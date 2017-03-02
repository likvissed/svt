require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Inv
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Krasnoyarsk'
    config.i18n.default_locale = :ru

    # Provides support for Cross-Origin Resource Sharing (CORS)
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'http://***REMOVED***', 'https://***REMOVED***.***REMOVED***.ru'
        resource '/***REMOVED***_invents/init/*', :headers => :any, :methods => [:get]
        resource '/***REMOVED***_invents/show_division_data/*', :headers => :any, :methods => [:get]
        resource '/workplaces/', :headers => :any, :methods => [:post]
      end
    end
  end
end
