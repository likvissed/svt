require 'spec_helper'

RSpec.configure do |config|
  Capybara.javascript_driver = :webkit

  config.use_transactional_fixtures = false

  # Список таблиц, которые запрещено очищать
  keep_tables = %w[
    invent_type invent_property_to_type invent_property invent_property_list invent_vendor invent_model
    invent_model_property_list invent_workplace_specialization invent_workplace_type
  ]

  # Выполняется перед запуском всего файла. Очищать с помощью truncation
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, except: keep_tables)
  end

  # Перед каждым тестом устанавливаем стратегию transaction. То есть данные не сохраняются в базу. Транзакция очищается
  # после завершения теста.
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  # Для каждой спеки с js: true использовать truncation. Данные создаются, но после уничтожаются.
  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation, { except: keep_tables }
  end

  # Начать отслеживать изменения.
  config.before(:each) do
    DatabaseCleaner.start
  end

  # Вызывать очистку после теста.
  config.after(:each) do
    DatabaseCleaner.clean
  end
end

Capybara::Webkit.configure do |config|
  config.allow_unknown_urls
end

# Описание настроек прокси:
# https://gist.github.com/tychobrailleur/5712504
# ENV['NO_PROXY'] = ENV['no_proxy'] = '127.0.0.1'
# Capybara.register_driver :selenium do |app|
#   profile = Selenium::WebDriver::Firefox::Profile.new
#   profile['network.proxy.type'] = 3
#   client = Selenium::WebDriver::Remote::Http::Default.new
#   client.read_timeout = 120 # instead of the default 60

# Capybara::Selenium::Driver.new(app, browser: :firefox, profile: profile, http_client: client)
# end

# Capybara.configure do |config|
#   config.default_driver = :selenium
#   config.app_host = "http://#{SERVER_CONFIG['hostname']}"
# end

# Capybara.default_driver = :selenium
# Capybara.javascript_driver = :selenium