require 'spec_helper'
require 'sidekiq/testing'

RSpec.configure do |config|
  Sidekiq::Testing.inline!

  config.include FeatureMacros, type: :feature

  config.use_transactional_fixtures = false

  OmniAuth.config.test_mode = true

  # Список таблиц, которые запрещено очищать
  saved_tables = %w[
    invent_type invent_property_to_type invent_property invent_property_list invent_vendor invent_model
    invent_model_property_list invent_workplace_specialization invent_workplace_type invent_pc_exceptions
  ]

  local_db = Rails.configuration.database_configuration[Rails.env]
  invent_db = Rails.configuration.database_configuration["#{Rails.env}_invent"]

  # Выполняется перед запуском всего файла. Очищать с помощью truncation
  config.before(:suite) do
    ActiveRecord::Base.establish_connection invent_db
    DatabaseCleaner.clean_with(:truncation, except: saved_tables)
    ActiveRecord::Base.establish_connection local_db
    DatabaseCleaner.clean_with(:truncation)
  end

  # Перед каждым тестом устанавливаем стратегию transaction. То есть данные не сохраняются в базу. Транзакция очищается
  # после завершения теста.
  config.before(:each) do
    Sidekiq::Worker.clear_all
    ActiveRecord::Base.establish_connection invent_db
    DatabaseCleaner.strategy = :transaction
    ActiveRecord::Base.establish_connection local_db
    DatabaseCleaner.strategy = :transaction
  end

  # Для каждой спеки с js: true использовать truncation. Данные создаются, но после уничтожаются.
  config.before(:each, js: true) do
    ActiveRecord::Base.establish_connection invent_db
    DatabaseCleaner.strategy = :truncation, { except: saved_tables }
    ActiveRecord::Base.establish_connection local_db
    DatabaseCleaner.strategy = :truncation
  end

  # Начать отслеживать изменения.
  config.before(:each) do
    ActiveRecord::Base.establish_connection invent_db
    DatabaseCleaner.start
    ActiveRecord::Base.establish_connection local_db
    DatabaseCleaner.start
  end

  # Вызывать очистку после теста.
  config.append_after(:each) do
    ActiveRecord::Base.establish_connection invent_db
    DatabaseCleaner.clean_with(:truncation, except: saved_tables)
    ActiveRecord::Base.establish_connection local_db
    DatabaseCleaner.clean
  end
end
