source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Provides support for Cross-Origin Resource Sharing (CORS)
gem 'rack-cors', require: 'rack/cors'

# For usage 'respond_to/respond_with'
gem 'binding_of_caller'
gem 'responders'

# Background processing
gem 'sidekiq'
gem 'sidekiq-scheduler'

# Authorization
gem 'devise'
gem 'omniauth'
gem 'pundit'
gem 'rest-client'

# MySQL
gem 'mysql2'
# Split into read and write for different hosts
gem 'makara'

# Other
gem 'awesome_print'
gem 'bootstrap-sass'
gem 'colorize'
gem 'dotenv-rails'
gem 'font-awesome-rails'
gem 'php_serialize'
gem 'rails-i18n'
gem 'rubocop', require: false
gem 'safe_attributes'
gem 'simple_form'
gem 'slim'
gem 'webpacker'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.1'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
# gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 3.0'
# Redis cache store
gem 'redis-rails'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

group :test do
  gem 'database_cleaner'
  gem 'json_spec'
  gem 'shoulda-matchers'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri

  # Testing
  gem 'factory_bot_rails'
  gem 'guard'
  gem 'guard-rspec', require: false
  gem 'rails-controller-testing'
  gem 'rspec-its'
  gem 'rspec-rails', '3.5.0'
end

group :development do
  gem 'listen', '~> 3.0.5'
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Rails panel
  # gem 'meta_request'
  # View errors
  gem 'better_errors'
  gem 'bullet'

  # Deploy application
  gem 'capistrano', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-passenger', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rbenv', require: false
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
