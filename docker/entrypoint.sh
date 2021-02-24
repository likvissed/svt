#! /bin/bash

set -ex

export WEB_CONCURRENCY=$WEB_CONCURRENCY
export RAILS_MAX_THREADS=$RAILS_MAX_THREADS

# Install yarn packages
yarn install

# Install gems
bundle install --jobs 4 --without development test
bundle exec rails db:migrate 2>/dev/null || bundle exec rails db:setup
bundle exec rake assets:precompile

exec "$@"
