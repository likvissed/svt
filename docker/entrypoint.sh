#! /bin/bash

set -e

export WEB_CONCURRENCY=$WEB_CONCURRENCY
export RAILS_MAX_THREADS=$RAILS_MAX_THREADS

echo 'Check database connection'
until nc -vz mysql 3306; do
  sleep 1
done
echo 'Database is ready'

bundle exec rails db:migrate 2>/dev/null || bundle exec rails db:setup
bundle exec rake assets:precompile

exec "$@"
