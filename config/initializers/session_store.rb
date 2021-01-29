# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :redis_store, {
  servers: [
    { host: ENV['REDIS_HOST'], port: 6379, db: 2 },
  ],
  key: '_inv_session'
}
